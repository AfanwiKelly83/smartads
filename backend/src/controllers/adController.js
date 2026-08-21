const path = require('path');
const { Advertisement, User, Notification } = require('../models');
const { verifyAdMedia } = require('../services/aiVerificationService');

// POST /api/ads/upload
const uploadAd = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Please upload an image or video file.' });
    }

    const { title, description, mediaType, durationSeconds } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Advertisement title is required.' });
    }

    const mediaUrl = `/uploads/ads/${req.file.filename}`;
    const detectedType = req.file.mimetype.startsWith('video') ? 'VIDEO' : 'IMAGE';

    const ad = await Advertisement.create({
      advertiserId: req.user.id,
      title,
      description,
      mediaUrl,
      mediaType: mediaType || detectedType,
      durationSeconds: durationSeconds || (detectedType === 'VIDEO' ? 30 : 15),
      verificationStatus: 'PENDING'
    });

    // Run AI Media Verification Service in background
    const filePath = req.file.path;
    const aiResult = await verifyAdMedia(filePath, ad.mediaType);

    ad.verificationStatus = aiResult.status;
    ad.verificationNotes = aiResult.notes;
    ad.aiConfidenceScore = aiResult.confidenceScore;
    ad.aiFlaggedReason = aiResult.flaggedReason;
    await ad.save();

    // Create Notification
    await Notification.create({
      userId: req.user.id,
      title: 'Advertisement Uploaded & AI Checked',
      message: `Your advertisement "${ad.title}" has been processed. AI verification result: ${ad.verificationStatus}.`,
      type: 'AD_VERIFICATION'
    });

    return res.status(201).json({
      success: true,
      message: 'Advertisement uploaded and AI verification complete.',
      data: ad
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/ads
const getAllAds = async (req, res, next) => {
  try {
    let whereClause = {};
    if (req.user.role !== 'ADMIN') {
      whereClause.advertiserId = req.user.id;
    }

    const ads = await Advertisement.findAll({
      where: whereClause,
      include: [{ model: User, as: 'advertiser', attributes: ['id', 'name', 'email'] }]
    });

    return res.json({
      success: true,
      data: ads
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/ads/:id
const getAdById = async (req, res, next) => {
  try {
    const ad = await Advertisement.findByPk(req.params.id, {
      include: [{ model: User, as: 'advertiser', attributes: ['id', 'name', 'email'] }]
    });

    if (!ad) {
      return res.status(404).json({ success: false, message: 'Advertisement not found.' });
    }

    if (req.user.role !== 'ADMIN' && ad.advertiserId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Unauthorized access to this advertisement.' });
    }

    return res.json({
      success: true,
      data: ad
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/ads/:id/verify (Admin moderation endpoint)
const verifyAd = async (req, res, next) => {
  try {
    const { status, notes } = req.body;

    if (!['APPROVED', 'REJECTED'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Status must be APPROVED or REJECTED.' });
    }

    const ad = await Advertisement.findByPk(req.params.id);
    if (!ad) {
      return res.status(404).json({ success: false, message: 'Advertisement not found.' });
    }

    ad.verificationStatus = status;
    ad.verificationNotes = notes || (status === 'APPROVED' ? 'Manually approved by administrator.' : 'Rejected by administrator.');
    await ad.save();

    // Create user notification
    await Notification.create({
      userId: ad.advertiserId,
      title: `Advertisement ${status}`,
      message: `Your advertisement "${ad.title}" status is now ${status}. Notes: ${ad.verificationNotes}`,
      type: 'AD_VERIFICATION'
    });

    return res.json({
      success: true,
      message: `Advertisement status updated to ${status}.`,
      data: ad
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/ads/:id
const deleteAd = async (req, res, next) => {
  try {
    const ad = await Advertisement.findByPk(req.params.id);

    if (!ad) {
      return res.status(404).json({ success: false, message: 'Advertisement not found.' });
    }

    if (req.user.role !== 'ADMIN' && ad.advertiserId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to delete this advertisement.' });
    }

    await ad.destroy();

    return res.json({
      success: true,
      message: 'Advertisement deleted successfully.'
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  uploadAd,
  getAllAds,
  getAdById,
  verifyAd,
  deleteAd
};
