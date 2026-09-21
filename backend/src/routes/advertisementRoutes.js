const express = require('express');
const router = express.Router();
const {
  createAdvertisement,
  getAllAdvertisements,
  getOwnerAdvertisements,
  getFlaggedAdvertisements,
  adminReviewAdvertisement,
  getAdvertisementById,
  updateAdvertisement,
  deleteAdvertisement
} = require('../controllers/advertisementController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.use(requireAuth);

router.get('/owner-ads', requireRole('BILLBOARD_OWNER', 'ADMIN'), getOwnerAdvertisements);
router.get('/flagged', requireRole('ADMIN'), getFlaggedAdvertisements);
router.put('/:id/admin-review', requireRole('ADMIN'), adminReviewAdvertisement);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), upload.single('media'), createAdvertisement);
router.get('/', getAllAdvertisements);
router.get('/:id', getAdvertisementById);
router.put('/:id', requireRole('ADVERTISER', 'ADMIN'), upload.single('media'), updateAdvertisement);
router.delete('/:id', requireRole('ADVERTISER', 'ADMIN'), deleteAdvertisement);

module.exports = router;
