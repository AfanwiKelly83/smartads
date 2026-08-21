const express = require('express');
const router = express.Router();
const {
  createCampaign,
  getAllCampaigns,
  getCampaignById
} = require('../controllers/campaignController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), createCampaign);
router.get('/', getAllCampaigns);
router.get('/:id', getCampaignById);

module.exports = router;
