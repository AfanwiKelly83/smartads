const { PlaybackLog, Campaign, Billboard, Advertisement } = require('../models');

// POST /api/tracking/log
const logPlayback = async (req, res, next) => {
  try {
    const { billboardId, campaignId, adId, durationPlayed, status, errorMessage } = req.body;

    if (!billboardId || !campaignId || !adId) {
      return res.status(400).json({
        success: false,
        message: 'billboardId, campaignId, and adId are required.'
      });
    }

    const log = await PlaybackLog.create({
      billboardId,
      campaignId,
      adId,
      playedAt: new Date(),
      durationPlayed: durationPlayed || 15,
      status: status || 'SUCCESS',
      errorMessage: errorMessage || null
    });

    return res.status(201).json({
      success: true,
      message: 'Playback log recorded.',
      data: log
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/tracking/campaign/:campaignId
const getCampaignTracking = async (req, res, next) => {
  try {
    const { campaignId } = req.params;

    const campaign = await Campaign.findByPk(campaignId, {
      include: [{ model: Advertisement, as: 'advertisement' }]
    });

    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    const totalPlays = await PlaybackLog.count({ where: { campaignId } });
    const successfulPlays = await PlaybackLog.count({ where: { campaignId, status: 'SUCCESS' } });
    const errorPlays = await PlaybackLog.count({ where: { campaignId, status: 'ERROR' } });

    const totalAirTimeSeconds = await PlaybackLog.sum('durationPlayed', { where: { campaignId, status: 'SUCCESS' } }) || 0;

    return res.json({
      success: true,
      data: {
        campaignId,
        campaignName: campaign.name,
        adTitle: campaign.advertisement ? campaign.advertisement.title : null,
        totalPlays,
        successfulPlays,
        errorPlays,
        totalAirTimeMinutes: (totalAirTimeSeconds / 60).toFixed(2),
        deliveryProgressPercentage: Math.min(100, Math.round((successfulPlays / 100) * 100)) // Scaled progress percentage
      }
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/tracking/billboard/:billboardId
const getBillboardLogs = async (req, res, next) => {
  try {
    const { billboardId } = req.params;

    const logs = await PlaybackLog.findAll({
      where: { billboardId },
      order: [['playedAt', 'DESC']],
      limit: 100,
      include: [
        { model: Campaign, as: 'campaign', attributes: ['id', 'name'] },
        { model: Advertisement, as: 'advertisement', attributes: ['id', 'title'] }
      ]
    });

    return res.json({
      success: true,
      data: logs
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  logPlayback,
  getCampaignTracking,
  getBillboardLogs
};
