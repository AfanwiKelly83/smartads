const express = require('express');
const router = express.Router();
const { register, login, getProfile } = require('../controllers/authController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.post('/register', register);
router.post('/login', login);
router.get('/me', requireAuth, getProfile);

module.exports = router;
