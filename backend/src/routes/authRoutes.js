const express = require('express');
const router = express.Router();
const { register, registerOwner, login, getProfile, updateProfile, changePassword } = require('../controllers/authController');
const { requireAuth } = require('../middlewares/authMiddleware');

router.post('/register', register);
router.post('/register-owner', registerOwner);
router.post('/login', login);
router.get('/me', requireAuth, getProfile);
router.put('/me', requireAuth, updateProfile);
router.post('/change-password', requireAuth, changePassword);

module.exports = router;
