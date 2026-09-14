const express = require('express');
const router = express.Router();
const { createPayment, getAllPayments } = require('../controllers/paymentController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), createPayment);
router.get('/', requireRole('ADMIN'), getAllPayments);

module.exports = router;
