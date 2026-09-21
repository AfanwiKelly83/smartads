const express = require('express');
const router = express.Router();
const { createPayment, getOwnerEarnings, getAllPayments } = require('../controllers/paymentController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), createPayment);
router.get('/owner-earnings', requireRole('BILLBOARD_OWNER', 'ADMIN'), getOwnerEarnings);
router.get('/', requireRole('ADMIN', 'BILLBOARD_OWNER'), getAllPayments);

module.exports = router;
