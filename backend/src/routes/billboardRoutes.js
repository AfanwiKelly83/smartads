const express = require('express');
const router = express.Router();
const {
  createBillboard,
  getAllBillboards,
  getBillboardById,
  updateBillboard,
  deleteBillboard
} = require('../controllers/billboardController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.get('/', getAllBillboards);
router.get('/:id', getBillboardById);

// Admin-only billboard management
router.post('/', requireAuth, requireRole('ADMIN'), createBillboard);
router.put('/:id', requireAuth, requireRole('ADMIN'), updateBillboard);
router.delete('/:id', requireAuth, requireRole('ADMIN'), deleteBillboard);

module.exports = router;
