const express = require('express');
const router = express.Router();
const { getUserNotifications } = require('../controllers/notificationController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.get('/', requireAuth, getUserNotifications);

module.exports = router;
