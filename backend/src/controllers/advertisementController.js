const { Advertisement, User, Notification, Billboard, Booking, Campaign } = require('../models');
const { verifyAdMedia } = require('../services/aiVerificationService');
const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');

// Helper to compute live progress percentage based on time or slot
const computeAdProgress = (ad) => {
  const startTime = ad.playStartTime || '08:00';
  const endTime = ad.playEndTime || '12:00';

  if (ad.approvalStatus === 'AI_REJECTED' || ad.approvalStatus === 'REJECTED') return 0;
  if (ad.approvalStatus === 'PENDING_AI_REVIEW' || ad.approvalStatus === 'AI_FLAGGED') return 0;

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
    return Math.min(Math.max(pct, 5), 95); // Active running progress
  }
};

// POST /api/v1/advertisements (Advertiser uploads ad)
const createAdvertisement = async (req, res, next) => {
  try {
    const { title, mediaType, playStartTime, playEndTime, mediaUrl } = req.body;

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

    // Live AI / Gemini Verification
    const verificationTarget = req.file ? req.file.path : filePath;
    const aiResult = await verifyAdMedia(verificationTarget, detectedType, title);

    const advertisement = await Advertisement.create({
      advertiserId: req.user.userId || req.user.id,
      title,
      mediaType: detectedType,
      filePath,
      fileSize,
      uploadDate: new Date(),
      approvalStatus: aiResult.status || 'AI_APPROVED',
      verificationNotes: aiResult.notes || 'Verification passed.',
      aiConfidenceScore: aiResult.confidenceScore || 0.95,
      aiFlaggedReason: aiResult.flaggedReason || null,
      playStartTime: playStartTime || '08:00',
      playEndTime: playEndTime || '12:00'
    });

    // Create Notification
    try {
      const statusLabel = aiResult.status === 'AI_APPROVED'
        ? 'passed AI verification (AI_APPROVED)'
        : (aiResult.status === 'AI_FLAGGED'
            ? 'was FLAGGED for Admin manual review'
            : 'was REJECTED by AI content policy');

      await Notification.create({
        userId: req.user.userId || req.user.id,
        message: `Advertisement "${advertisement.title}" ${statusLabel}.${aiResult.notes ? ` ${aiResult.notes}` : ''}`,
        notificationType: 'AD_UPLOAD',
        status: 'UNREAD'
      });
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: `Advertisement created. AI status: ${advertisement.approvalStatus}.`,
      data: advertisement,
      verification: aiResult
    });
  } catch (err) {
    next(err);
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

// GET /api/v1/advertisements/owner-ads (Advertisements on Owner's billboards)
const getOwnerAdvertisements = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.id;

    // 1. Find all billboards owned by this user
    const ownerBillboards = await Billboard.findAll({
      where: {
        [Op.or]: [{ ownerId: userId }, { createdBy: userId }]
      },
      attributes: ['billboardId', 'billboardName', 'billboardCode', 'location']
    });

    const billboardIds = ownerBillboards.map(b => b.billboardId);

    if (billboardIds.length === 0) {
      return res.json({ success: true, data: [] });
    }

    // 2. Find confirmed/active bookings on these billboards
    const bookings = await Booking.findAll({
      where: { billboardId: { [Op.in]: billboardIds } },
      include: [
        { model: Billboard, as: 'billboard', attributes: ['billboardId', 'billboardName', 'billboardCode', 'location'] },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] },
        { model: Campaign, as: 'campaign' }
      ]
    });

    // 3. Find advertisements for these campaigns/advertisers
    const advertiserIds = [...new Set(bookings.map(b => b.advertiserId))];
    const ads = await Advertisement.findAll({
      where: { advertiserId: { [Op.in]: advertiserIds } },
      include: [{ model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }],
      order: [['createdAt', 'DESC']]
    });

    const enrichedAds = ads.map(ad => {
      const plain = ad.toJSON();
      const progress = computeAdProgress(ad);
      // Link to relevant billboard if matching
      const relatedBooking = bookings.find(b => b.advertiserId === ad.advertiserId);
      return {
        ...plain,
        mediaUrl: plain.filePath,
        progressPercentage: progress,
        billboard: relatedBooking ? relatedBooking.billboard : null,
        booking: relatedBooking ? {
          bookingId: relatedBooking.bookingId,
          startDate: relatedBooking.startDate,
          endDate: relatedBooking.endDate,
          startTime: relatedBooking.startTime,
          endTime: relatedBooking.endTime,
          status: relatedBooking.status
        } : null,
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

// GET /api/v1/advertisements/flagged (Admin review queue)
const getFlaggedAdvertisements = async (req, res, next) => {
  try {
    const flaggedAds = await Advertisement.findAll({
      where: {
        approvalStatus: {
          [Op.in]: ['AI_FLAGGED', 'MANUAL_REVIEW', 'PENDING_AI_REVIEW']
        }
      },
      include: [{ model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }],
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: flaggedAds
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/advertisements/:id/admin-review (Admin APPROVE / REJECT / REQUEST_CORRECTION)
const adminReviewAdvertisement = async (req, res, next) => {
  try {
    const { action, notes, correctionReason } = req.body;
    const ad = await Advertisement.findByPk(req.params.id);

    if (!ad) {
      return res.status(404).json({ success: false, message: 'Advertisement not found.' });
    }

    const actionUpper = String(action || '').toUpperCase();
    if (!['APPROVE', 'REJECT', 'REQUEST_CORRECTION'].includes(actionUpper)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action. Allowed: [APPROVE, REJECT, REQUEST_CORRECTION]'
      });
    }

    if (actionUpper === 'APPROVE') {
      ad.approvalStatus = 'APPROVED';
    } else if (actionUpper === 'REJECT') {
      ad.approvalStatus = 'REJECTED';
    } else if (actionUpper === 'REQUEST_CORRECTION') {
      ad.approvalStatus = 'MANUAL_REVIEW';
    }

    if (notes) ad.adminNotes = notes;
    if (correctionReason) ad.correctionReason = correctionReason;

    await ad.save();

    // Notify advertiser
    try {
      await Notification.create({
        userId: ad.advertiserId,
        message: `Admin review for "${ad.title}": ${ad.approvalStatus}.${notes ? ` Notes: ${notes}` : ''}${correctionReason ? ` Correction requested: ${correctionReason}` : ''}`,
        notificationType: 'AD_REVIEW',
        status: 'UNREAD'
      });
    } catch (_) {}

    return res.json({
      success: true,
      message: `Advertisement status updated to ${ad.approvalStatus}.`,
      data: ad
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

    const requesterId = req.user.userId || req.user.id;
    if (req.user.role !== 'ADMIN' && req.user.role !== 'BILLBOARD_OWNER' && ad.advertiserId !== requesterId) {
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

    const { title, description, mediaType, playStartTime, playEndTime, mediaUrl } = req.body;

    if (title !== undefined && title.trim() === '') {
      return res.status(400).json({ success: false, message: 'Title cannot be empty.' });
    }

    let mediaChanged = false;

    if (req.file) {
      try {
        const oldPath = path.join(__dirname, '../../', ad.filePath || '');
        if (oldPath && fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      } catch (e) {}

      ad.filePath = `/uploads/ads/${req.file.filename}`;
      ad.fileSize = req.file.size;
      ad.mediaType = req.file.mimetype.startsWith('video') ? 'VIDEO' : 'IMAGE';
      ad.uploadDate = new Date();
      mediaChanged = true;
    } else if (mediaUrl && mediaUrl !== ad.filePath) {
      ad.filePath = mediaUrl;
      mediaChanged = true;
    }

    if (title !== undefined) ad.title = title;
    if (description !== undefined) ad.description = description;
    if (mediaType !== undefined) ad.mediaType = mediaType;
    if (playStartTime !== undefined) ad.playStartTime = playStartTime;
    if (playEndTime !== undefined) ad.playEndTime = playEndTime;

    // If media or title changed, re-run AI / Gemini verification
    if (mediaChanged) {
      const verificationTarget = req.file ? req.file.path : ad.filePath;
      const aiResult = await verifyAdMedia(verificationTarget, ad.mediaType, ad.title);
      ad.approvalStatus = aiResult.status || 'AI_APPROVED';
      ad.verificationNotes = aiResult.notes;
      ad.aiConfidenceScore = aiResult.confidenceScore;
      ad.aiFlaggedReason = aiResult.flaggedReason;
    }

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

    try {
      const oldPath = path.join(__dirname, '../../', ad.filePath || '');
      if (oldPath && fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    } catch (e) {}

    await ad.destroy();

    return res.json({ success: true, message: 'Advertisement deleted.' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createAdvertisement,
  getAllAdvertisements,
  getOwnerAdvertisements,
  getFlaggedAdvertisements,
  adminReviewAdvertisement,
  getAdvertisementById,
  updateAdvertisement,
  deleteAdvertisement
};
