const express = require('express');
const router = express.Router();
const {
  createBooking,
  getAllBookings,
  getBookingById,
  getBillboardAvailability
} = require('../controllers/bookingController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), createBooking);
router.get('/', getAllBookings);
router.get('/availability/:billboardId', getBillboardAvailability);
router.get('/:id', getBookingById);

module.exports = router;
