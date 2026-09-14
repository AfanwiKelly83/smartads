const express = require('express');
const router = express.Router();
const { getProfile, updateProfile, getAllUsers, updateUserByAdmin } = require('../controllers/userController');
const { authenticate, requireRole } = require('../middlewares/authMiddleware');

// Protect all profile routes with authenticate middleware
router.use(authenticate);

router.get('/', requireRole('ADMIN'), getAllUsers);
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.put('/:userId', requireRole('ADMIN'), updateUserByAdmin);

module.exports = router;
