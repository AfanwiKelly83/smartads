const express = require('express');
const router = express.Router();
const {
  createBooking,
  getAllBookings,
  getOwnerBookings,
  getBookingById,
  getBillboardAvailability
} = require('../controllers/bookingController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), createBooking);
router.get('/', getAllBookings);
router.get('/owner-bookings', requireRole('BILLBOARD_OWNER', 'ADMIN'), getOwnerBookings);
router.get('/availability/:billboardId', getBillboardAvailability);
router.get('/:id', getBookingById);

module.exports = router;
