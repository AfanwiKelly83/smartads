const { Advertisement, User, Notification } = require('../models');
const { verifyAdvertisementWithGemini } = require('../services/advertisementVerificationService');

// POST /api/v1/advertisements (Advertiser uploads ad)
const createAdvertisement = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Please upload an image or video file.' });
    }

    const { title, mediaType, playStartTime, playEndTime } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Advertisement title is required.' });
    }

    const filePath = `/uploads/ads/${req.file.filename}`;
    const detectedType = req.file.mimetype.startsWith('video') ? 'VIDEO' : 'IMAGE';

    const advertisement = await Advertisement.create({
      advertiserId: req.user.userId || req.user.id,
      title,
      mediaType: mediaType || detectedType,
      filePath,
      fileSize: req.file.size,
      uploadDate: new Date(),
      approvalStatus: 'PENDING',
      playStartTime: playStartTime || '08:00',
      playEndTime: playEndTime || '22:00'
    });

    // Run Gemini AI Verification
    const aiResult = await verifyAdvertisementWithGemini(req.file.path, advertisement.mediaType);
    advertisement.approvalStatus = aiResult.status;
    await advertisement.save();

    // Create Notification
    await Notification.create({
      userId: req.user.userId || req.user.id,
      message: `Advertisement "${advertisement.title}" uploaded. Gemini AI status: ${advertisement.approvalStatus}.`,
      notificationType: 'AD_VERIFICATION',
      status: 'UNREAD'
    });

    return res.status(201).json({
      success: true,
      message: 'Advertisement uploaded and processed by Gemini AI.',
      data: advertisement
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
      include: [{ model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }]
    });

    return res.json({
      success: true,
      data: ads
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

    return res.json({
      success: true,
      data: ad
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createAdvertisement,
  getAllAdvertisements,
  getAdvertisementById
};
