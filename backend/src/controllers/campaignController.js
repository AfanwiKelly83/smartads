const { Campaign, Billboard, User, CampaignBillboard } = require('../models');

// POST /api/v1/campaigns
const createCampaign = async (req, res, next) => {
  try {
    const { campaignType, startDate, endDate, repeatOption, billboardIds } = req.body;

    if (!startDate || !endDate) {
      return res.status(400).json({ success: false, message: 'startDate and endDate are required.' });
    }

    const campaign = await Campaign.create({
      advertiserId: req.user.userId || req.user.id,
      campaignType: campaignType || 'STANDARD',
      startDate,
      endDate,
      repeatOption: repeatOption || 'DAILY',
      campaignStatus: 'DRAFT',
      totalCost: 0.0
    });

    // Link billboards via CampaignBillboard M:N relationship
    if (billboardIds && Array.isArray(billboardIds) && billboardIds.length > 0) {
      for (const billboardId of billboardIds) {
        await CampaignBillboard.create({
          campaignId: campaign.campaignId,
          billboardId
        });
      }
    }

    return res.status(201).json({
      success: true,
      message: 'Campaign created successfully.',
      data: campaign
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/campaigns
const getAllCampaigns = async (req, res, next) => {
  try {
    let whereClause = {};
    if (req.user.role !== 'ADMIN') {
      whereClause.advertiserId = req.user.userId || req.user.id;
    }

    const campaigns = await Campaign.findAll({
      where: whereClause,
      include: [
        { model: Billboard, as: 'billboards', through: { attributes: [] } },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }
      ]
    });

    return res.json({
      success: true,
      data: campaigns
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/campaigns/:id
const getCampaignById = async (req, res, next) => {
  try {
    const campaign = await Campaign.findByPk(req.params.id, {
      include: [
        { model: Billboard, as: 'billboards', through: { attributes: [] } },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }
      ]
    });

    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    return res.json({
      success: true,
      data: campaign
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createCampaign,
  getAllCampaigns,
  getCampaignById
};
