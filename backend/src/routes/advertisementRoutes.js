const express = require('express');
const router = express.Router();
const {
  createAdvertisement,
  getAllAdvertisements,
  getAdvertisementById
} = require('../controllers/advertisementController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), upload.single('media'), createAdvertisement);
router.get('/', getAllAdvertisements);
router.get('/:id', getAdvertisementById);

module.exports = router;
