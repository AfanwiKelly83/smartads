const express = require('express');
const router = express.Router();
const { getSystemStatistics } = require('../controllers/analyticsController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.get('/', requireAuth, requireRole('ADMIN'), getSystemStatistics);

module.exports = router;
