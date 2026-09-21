const express = require('express');
const router = express.Router();
const { postHeartbeat, getDevices } = require('../controllers/iotController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.post('/heartbeat', postHeartbeat);
router.get('/devices', requireAuth, requireRole('ADMIN', 'BILLBOARD_OWNER'), getDevices);

module.exports = router;
