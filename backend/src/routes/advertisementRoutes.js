const express = require('express');
const router = express.Router();
const {
  createAdvertisement,
  getAllAdvertisements,
  getAdvertisementById
  , updateAdvertisement, deleteAdvertisement
} = require('../controllers/advertisementController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.use(requireAuth);

router.post('/', requireRole('ADVERTISER', 'ADMIN'), upload.single('media'), createAdvertisement);
router.get('/', getAllAdvertisements);
router.get('/:id', getAdvertisementById);
router.put('/:id', requireRole('ADVERTISER', 'ADMIN'), upload.single('media'), updateAdvertisement);
router.delete('/:id', requireRole('ADVERTISER', 'ADMIN'), deleteAdvertisement);

module.exports = router;
