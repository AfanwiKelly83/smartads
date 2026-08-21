const express = require('express');
const router = express.Router();
const {
  uploadAd,
  getAllAds,
  getAdById,
  verifyAd,
  deleteAd
} = require('../controllers/adController');
const { authenticateToken, authorize } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.use(authenticateToken);

router.post('/upload', upload.single('media'), uploadAd);
router.get('/', getAllAds);
router.get('/:id', getAdById);
router.put('/:id/verify', authorize('ADMIN'), verifyAd);
router.delete('/:id', deleteAd);

module.exports = router;
