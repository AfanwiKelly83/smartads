const express = require('express');
const router = express.Router();
const {
  createBooking,
  getAllBookings,
  getBookingById
} = require('../controllers/bookingController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), createBooking);
router.get('/', getAllBookings);
router.get('/:id', getBookingById);

module.exports = router;
