const express = require('express');
const router = express.Router();
const {
  logPlayback,
  getCampaignTracking,
  getBillboardLogs
} = require('../controllers/trackingController');
const { authenticateToken } = require('../middlewares/authMiddleware');

router.post('/log', logPlayback);
router.get('/campaign/:campaignId', authenticateToken, getCampaignTracking);
router.get('/billboard/:billboardId', authenticateToken, getBillboardLogs);

module.exports = router;
