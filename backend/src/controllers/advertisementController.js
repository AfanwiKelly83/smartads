const { Advertisement, User, Notification } = require('../models');
const { verifyAdMedia } = require('../services/aiVerificationService');
const fs = require('fs');
const path = require('path');

// POST /api/v1/advertisements (Advertiser uploads ad)
const createAdvertisement = async (req, res, next) => {
  try {
    const { title, mediaType, playStartTime, playEndTime, slotTime, duration, mediaUrl } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Advertisement title is required.' });
    }

    let filePath;
    let fileSize = null;
    let detectedType = mediaType || 'IMAGE';

    if (req.file) {
      filePath = `/uploads/ads/${req.file.filename}`;
      fileSize = req.file.size;
      detectedType = req.file.mimetype.startsWith('video') ? 'VIDEO' : 'IMAGE';
    } else if (mediaUrl) {
      filePath = mediaUrl;
    } else {
      filePath = detectedType === 'VIDEO'
        ? 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4'
        : 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800';
    }

    // AI Verification disabled in this version
    // const aiResult = await verifyAdMedia(req.file ? req.file.path : filePath, detectedType);
    const aiResult = { status: 'APPROVED', notes: 'Auto-approved (AI verification disabled)', confidenceScore: 100, flaggedReason: null };

    const advertisement = await Advertisement.create({
      advertiserId: req.user.userId || req.user.id,
      title,
      mediaType: detectedType,
      filePath,
      fileSize,
      uploadDate: new Date(),
      approvalStatus: aiResult.status,
      verificationNotes: aiResult.notes,
      aiConfidenceScore: aiResult.confidenceScore,
      aiFlaggedReason: aiResult.flaggedReason,
      playStartTime: playStartTime || '08:00',
      playEndTime: playEndTime || '12:00'
    });

    // Create Notification (upload received)
    try {
      await Notification.create({
        userId: req.user.userId || req.user.id,
        message: `Advertisement "${advertisement.title}" uploaded. AI verification result: ${aiResult.status}.`,
        notificationType: 'AD_UPLOAD',
        status: 'UNREAD'
      });
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: `Advertisement created. AI verification result: ${aiResult.status}.`,
      data: advertisement,
      verification: aiResult
    });
  } catch (err) {
    next(err);
  }
};

// Helper to compute live progress percentage based on time or slot
const computeAdProgress = (ad) => {
  const startTime = ad.playStartTime || '08:00';
  const endTime = ad.playEndTime || '12:00';

  // If status is rejected or pending approval
  if (ad.approvalStatus === 'PENDING') return 0;
  if (ad.approvalStatus === 'REJECTED') return 0;

  // Compute based on current time
  const now = new Date();
  const [startH, startM] = startTime.split(':').map(Number);
  const [endH, endM] = endTime.split(':').map(Number);

  const startMinutes = (startH || 8) * 60 + (startM || 0);
  const endMinutes = (endH || 12) * 60 + (endM || 0);
  const currentMinutes = now.getHours() * 60 + now.getMinutes();

  if (currentMinutes < startMinutes) {
    return 0; // Still to start
  } else if (currentMinutes >= endMinutes) {
    return 100; // Completed
  } else {
    const elapsed = currentMinutes - startMinutes;
    const total = endMinutes - startMinutes;
    const pct = total > 0 ? Math.round((elapsed / total) * 100) : 50;
    return Math.min(Math.max(pct, 10), 95); // Running progress
  }
};

// GET /api/v1/advertisements
const getAllAdvertisements = async (req, res, next) => {
  try {
    let whereClause = {};
    if (req.user.role !== 'ADMIN') {
      whereClause.advertiserId = req.user.userId || req.user.id;
    }

    const ads = await Advertisement.findAll({
      where: whereClause,
      include: [{ model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }],
      order: [['createdAt', 'DESC']]
    });

    const enrichedAds = ads.map(ad => {
      const plain = ad.toJSON();
      const progress = computeAdProgress(ad);
      return {
        ...plain,
        mediaUrl: plain.filePath,
        progressPercentage: progress,
        slotTime: `${plain.playStartTime || '08:00 AM'} - ${plain.playEndTime || '12:00 PM'}`,
        status: progress === 0 ? 'SCHEDULED' : (progress === 100 ? 'COMPLETED' : 'RUNNING')
      };
    });

    return res.json({
      success: true,
      data: enrichedAds
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/advertisements/:id
const getAdvertisementById = async (req, res, next) => {
  try {
    const ad = await Advertisement.findByPk(req.params.id, {
      include: [{ model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }]
    });

    if (!ad) {
      return res.status(404).json({ success: false, message: 'Advertisement not found.' });
    }

    // Enforce ownership: advertisers can only access their own advertisements
    const requesterId = req.user.userId || req.user.id;
    if (req.user.role !== 'ADMIN' && ad.advertiserId !== requesterId) {
      return res.status(403).json({ success: false, message: 'Forbidden: access to this advertisement is denied.' });
    }

    return res.json({
      success: true,
      data: ad
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/advertisements/:id
const updateAdvertisement = async (req, res, next) => {
  try {
    const ad = await Advertisement.findByPk(req.params.id);
    if (!ad) return res.status(404).json({ success: false, message: 'Advertisement not found.' });

    const requesterId = req.user.userId || req.user.id;
    if (req.user.role !== 'ADMIN' && ad.advertiserId !== requesterId) {
      return res.status(403).json({ success: false, message: 'Forbidden: you cannot update this advertisement.' });
    }

    const { title, description, mediaType, playStartTime, playEndTime, mediaUrl, slotTime } = req.body;

    if (title !== undefined && title.trim() === '') {
      return res.status(400).json({ success: false, message: 'Title cannot be empty.' });
    }

    // If a new file is uploaded, remove old file and update filePath/fileSize
    if (req.file) {
      try {
        const oldPath = path.join(__dirname, '../../', ad.filePath || '');
        if (oldPath && fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      } catch (e) {
        // ignore delete errors
      }

      ad.filePath = `/uploads/ads/${req.file.filename}`;
      ad.fileSize = req.file.size;
      ad.mediaType = req.file.mimetype.startsWith('video') ? 'VIDEO' : 'IMAGE';
      ad.uploadDate = new Date();
      // AI Verification disabled in this version
      // const aiResult = await verifyAdMedia(req.file.path, ad.mediaType);
      const aiResult = { status: 'APPROVED', notes: 'Auto-approved (AI verification disabled)', confidenceScore: 100, flaggedReason: null };
      ad.approvalStatus = aiResult.status;
      ad.verificationNotes = aiResult.notes;
      ad.aiConfidenceScore = aiResult.confidenceScore;
      ad.aiFlaggedReason = aiResult.flaggedReason;
    } else if (mediaUrl) {
      ad.filePath = mediaUrl;
    }

    if (title !== undefined) ad.title = title;
    if (description !== undefined) ad.description = description;
    if (mediaType !== undefined) ad.mediaType = mediaType;
    if (playStartTime !== undefined) ad.playStartTime = playStartTime;
    if (playEndTime !== undefined) ad.playEndTime = playEndTime;

    await ad.save();

    const plain = ad.toJSON();
    const progress = computeAdProgress(ad);
    const enriched = {
      ...plain,
      mediaUrl: plain.filePath,
      progressPercentage: progress,
      slotTime: `${plain.playStartTime || '08:00 AM'} - ${plain.playEndTime || '12:00 PM'}`,
      status: progress === 0 ? 'SCHEDULED' : (progress === 100 ? 'COMPLETED' : 'RUNNING')
    };

    return res.json({ success: true, message: 'Advertisement updated successfully.', data: enriched });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/v1/advertisements/:id
const deleteAdvertisement = async (req, res, next) => {
  try {
    const ad = await Advertisement.findByPk(req.params.id);
    if (!ad) return res.status(404).json({ success: false, message: 'Advertisement not found.' });

    const requesterId = req.user.userId || req.user.id;
    if (req.user.role !== 'ADMIN' && ad.advertiserId !== requesterId) {
      return res.status(403).json({ success: false, message: 'Forbidden: you cannot delete this advertisement.' });
    }

    // delete file if exists
    try {
      const oldPath = path.join(__dirname, '../../', ad.filePath || '');
      if (oldPath && fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    } catch (e) {
      // ignore
    }

    await ad.destroy();

    return res.json({ success: true, message: 'Advertisement deleted.' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createAdvertisement,
  getAllAdvertisements,
  getAdvertisementById,
  updateAdvertisement,
  deleteAdvertisement
};
