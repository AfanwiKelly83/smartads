const express = require('express');
const router = express.Router();
const {
  createBillboard,
  getAllBillboards,
  getMyBillboards,
  getBillboardById,
  updateBillboard,
  updateApprovalStatus,
  deleteBillboard
} = require('../controllers/billboardController');
const { requireAuth, requireRole } = require('../middlewares/authMiddleware');

router.get('/', getAllBillboards);
router.get('/my-billboards', requireAuth, requireRole('ADMIN', 'BILLBOARD_OWNER'), getMyBillboards);
router.get('/:id', getBillboardById);

// Billboard creation & management (Admin or Billboard Owner)
router.post('/', requireAuth, requireRole('ADMIN', 'BILLBOARD_OWNER'), createBillboard);
router.put('/:id/approval', requireAuth, requireRole('ADMIN'), updateApprovalStatus);
router.put('/:id', requireAuth, requireRole('ADMIN', 'BILLBOARD_OWNER'), updateBillboard);
router.delete('/:id', requireAuth, requireRole('ADMIN', 'BILLBOARD_OWNER'), deleteBillboard);

module.exports = router;
