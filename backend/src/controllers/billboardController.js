const { Billboard, User, Notification } = require('../models');
const { generateBillboardQRCode } = require('../services/qrCodeService');
const { getBillboardCapacityAvailability, getBillboardTimeSlots } = require('../services/availabilityService');
const { Op } = require('sequelize');

/**
 * Generate unique public Billboard Code (BILL-001, BILL-002, ...)
 */
const generateUniqueBillboardCode = async () => {
  const count = await Billboard.count();
  let candidateNumber = count + 1;
  let candidateCode = `BILL-${String(candidateNumber).padStart(3, '0')}`;
  
  // Ensure uniqueness
  while (await Billboard.findOne({ where: { billboardCode: candidateCode } })) {
    candidateNumber++;
    candidateCode = `BILL-${String(candidateNumber).padStart(3, '0')}`;
  }
  return candidateCode;
};

// POST /api/v1/billboards (ADMIN or BILLBOARD_OWNER)
const createBillboard = async (req, res, next) => {
  try {
    const {
      billboardName,
      location,
      address,
      description,
      billboardType,
      width,
      height,
      resolution,
      pricePerHour,
      maxActiveCampaigns,
      operatingHours,
      images,
      videoDemo,
      technicalSpecs,
      additionalInfo,
      latitude,
      longitude,
      screenSize
    } = req.body;

    if (!billboardName || !location) {
      return res.status(400).json({
        success: false,
        message: 'billboardName and location are required.'
      });
    }

    const userId = req.user.userId || req.user.id;
    const isOwner = req.user.role === 'BILLBOARD_OWNER';
    const isAdmin = req.user.role === 'ADMIN';

    // Status: Owner created billboards require Admin approval
    const approvalStatus = isAdmin ? 'APPROVED' : 'PENDING_APPROVAL';

    const parsedLat = latitude !== undefined && latitude !== null && latitude !== '' ? parseFloat(latitude) : null;
    const parsedLng = longitude !== undefined && longitude !== null && longitude !== '' ? parseFloat(longitude) : null;
    const parsedRate = pricePerHour !== undefined && pricePerHour !== null && pricePerHour !== '' ? parseFloat(pricePerHour) : 15000.0;
    const parsedMaxCampaigns = maxActiveCampaigns !== undefined && maxActiveCampaigns !== null && maxActiveCampaigns !== '' ? Math.max(1, parseInt(maxActiveCampaigns, 10)) : 10;

    const billboardCode = await generateUniqueBillboardCode();

    const billboard = await Billboard.create({
      billboardCode,
      billboardName,
      ownerId: userId,
      createdBy: userId,
      location,
      address: address || location,
      description: description || 'Digital advertising display available for scheduled campaigns.',
      billboardType: billboardType || 'SMART_TV',
      width: width ? String(width) : '1920',
      height: height ? String(height) : '1080',
      resolution: resolution || '1920x1080',
      pricePerHour: parsedRate,
      maxActiveCampaigns: parsedMaxCampaigns,
      operatingHours: operatingHours || '06:00 - 22:00',
      images: images || null,
      videoDemo: videoDemo || null,
      technicalSpecs: technicalSpecs || null,
      additionalInfo: additionalInfo || null,
      approvalStatus,
      displayStatus: 'ACTIVE',
      availabilityStatus: 'AVAILABLE',
      latitude: parsedLat,
      longitude: parsedLng,
      screenSize: screenSize || 'Smart TV HD (1920x1080)'
    });

    // Automatically generate QR Code
    const qrCodePath = await generateBillboardQRCode(billboard);
    billboard.qrCode = qrCodePath;
    await billboard.save();

    // Create Notification
    try {
      await Notification.create({
        userId,
        message: isOwner
          ? `Your billboard "${billboard.billboardName}" (${billboard.billboardCode}) has been submitted for Admin approval.`
          : `Billboard "${billboard.billboardName}" (${billboard.billboardCode}) created and activated.`,
        notificationType: 'BILLBOARD_STATUS',
        status: 'UNREAD'
      });
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: isOwner
        ? 'Billboard created successfully. Status: PENDING_APPROVAL. QR code generated.'
        : 'Billboard created and approved successfully. QR code generated.',
      data: billboard
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/billboards (Public/Advertiser search returns APPROVED only, Admin can see all with ?all=true)
const getAllBillboards = async (req, res, next) => {
  try {
    const { all, search, status } = req.query;
    let whereClause = {};

    const isAdmin = req.user && req.user.role === 'ADMIN';

    if (!isAdmin || all !== 'true') {
      // Public / Advertisers only see APPROVED and ACTIVE billboards
      whereClause.approvalStatus = 'APPROVED';
      whereClause.displayStatus = { [Op.ne]: 'INACTIVE' };
    } else if (status) {
      whereClause.approvalStatus = status;
    }

    if (search) {
      whereClause[Op.or] = [
        { billboardName: { [Op.like]: `%${search}%` } },
        { location: { [Op.like]: `%${search}%` } },
        { billboardCode: { [Op.like]: `%${search}%` } }
      ];
    }

    const billboards = await Billboard.findAll({
      where: whereClause,
      include: [
        { model: User, as: 'owner', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] },
        { model: User, as: 'creator', attributes: ['userId', 'fullName', 'email'] }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: billboards
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/billboards/my-billboards (Billboard Owner's own billboards)
const getMyBillboards = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.id;

    const billboards = await Billboard.findAll({
      where: {
        [Op.or]: [
          { ownerId: userId },
          { createdBy: userId }
        ]
      },
      include: [
        { model: User, as: 'owner', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: billboards
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/billboards/:id (Lookup by ID or billboardCode)
const getBillboardById = async (req, res, next) => {
  try {
    const param = req.params.id;
    let billboard;

    if (/^\d+$/.test(param)) {
      billboard = await Billboard.findByPk(param, {
        include: [
          { model: User, as: 'owner', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] },
          { model: User, as: 'creator', attributes: ['userId', 'fullName', 'email'] }
        ]
      });
    } else {
      billboard = await Billboard.findOne({
        where: { billboardCode: param },
        include: [
          { model: User, as: 'owner', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] },
          { model: User, as: 'creator', attributes: ['userId', 'fullName', 'email'] }
        ]
      });
    }

    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    return res.json({
      success: true,
      data: billboard
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/billboards/:id (Admin or Resource Owner)
const updateBillboard = async (req, res, next) => {
  try {
    const billboard = await Billboard.findByPk(req.params.id);

    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    const userId = req.user.userId || req.user.id;
    const isAdmin = req.user.role === 'ADMIN';
    const isOwner = (billboard.ownerId === userId || billboard.createdBy === userId);

    if (!isAdmin && !isOwner) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You do not have permission to modify this billboard.'
      });
    }

    const {
      billboardName,
      location,
      address,
      description,
      billboardType,
      width,
      height,
      resolution,
      pricePerHour,
      maxActiveCampaigns,
      operatingHours,
      images,
      videoDemo,
      technicalSpecs,
      additionalInfo,
      displayStatus,
      availabilityStatus,
      latitude,
      longitude,
      screenSize
    } = req.body;

    if (billboardName) billboard.billboardName = billboardName;
    if (location) billboard.location = location;
    if (address) billboard.address = address;
    if (description) billboard.description = description;
    if (billboardType) billboard.billboardType = billboardType;
    if (width) billboard.width = String(width);
    if (height) billboard.height = String(height);
    if (resolution) billboard.resolution = resolution;
    if (pricePerHour !== undefined) billboard.pricePerHour = parseFloat(pricePerHour);
    if (maxActiveCampaigns !== undefined && maxActiveCampaigns !== null && maxActiveCampaigns !== '') {
      billboard.maxActiveCampaigns = Math.max(1, parseInt(maxActiveCampaigns, 10));
    }
    if (operatingHours) billboard.operatingHours = operatingHours;
    if (images) billboard.images = images;
    if (videoDemo) billboard.videoDemo = videoDemo;
    if (technicalSpecs) billboard.technicalSpecs = technicalSpecs;
    if (additionalInfo) billboard.additionalInfo = additionalInfo;
    if (displayStatus) billboard.displayStatus = displayStatus;
    if (availabilityStatus) billboard.availabilityStatus = availabilityStatus;
    if (latitude !== undefined) billboard.latitude = (latitude !== null && latitude !== '') ? parseFloat(latitude) : null;
    if (longitude !== undefined) billboard.longitude = (longitude !== null && longitude !== '') ? parseFloat(longitude) : null;
    if (screenSize) billboard.screenSize = screenSize;

    // Re-generate QR Code if needed or ensure it exists
    if (!billboard.qrCode) {
      billboard.qrCode = await generateBillboardQRCode(billboard);
    }

    await billboard.save();

    return res.json({
      success: true,
      message: 'Billboard updated successfully.',
      data: billboard
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/billboards/:id/availability?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
const getBillboardAvailability = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { startDate, endDate, date } = req.query;

    const queryStart = startDate || date || new Date().toISOString().slice(0, 10);
    const queryEnd = endDate || queryStart;

    const capacityData = await getBillboardCapacityAvailability({
      billboardId: Number(id),
      startDate: queryStart,
      endDate: queryEnd
    });

    const slots = await getBillboardTimeSlots({
      billboardId: Number(id),
      date: queryStart
    });

    return res.json({
      success: true,
      data: {
        ...capacityData,
        slots
      }
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/billboards/:id/approval (Admin only: Approve, Reject, Suspend, Unpublish)
const updateApprovalStatus = async (req, res, next) => {
  try {
    const { status, notes } = req.body;
    const allowedStatuses = ['APPROVED', 'REJECTED', 'SUSPENDED', 'UNPUBLISHED', 'PENDING_APPROVAL'];

    const nextStatus = String(status || '').toUpperCase();
    if (!allowedStatuses.includes(nextStatus)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: [${allowedStatuses.join(', ')}]`
      });
    }

    const billboard = await Billboard.findByPk(req.params.id);
    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    billboard.approvalStatus = nextStatus;
    if (nextStatus === 'APPROVED') {
      billboard.displayStatus = 'ACTIVE';
      billboard.availabilityStatus = 'AVAILABLE';
    } else if (nextStatus === 'SUSPENDED' || nextStatus === 'REJECTED') {
      billboard.displayStatus = 'INACTIVE';
      billboard.availabilityStatus = 'UNAVAILABLE';
    }
    await billboard.save();

    // Notify owner
    const targetUserId = billboard.ownerId || billboard.createdBy;
    if (targetUserId) {
      try {
        await Notification.create({
          userId: targetUserId,
          message: `Your billboard "${billboard.billboardName}" (${billboard.billboardCode}) is now ${nextStatus}.${notes ? ` Notes: ${notes}` : ''}`,
          notificationType: 'BILLBOARD_STATUS',
          status: 'UNREAD'
        });
      } catch (_) {}
    }

    return res.json({
      success: true,
      message: `Billboard approval status updated to ${nextStatus}.`,
      data: billboard
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/v1/billboards/:id (Admin or Resource Owner)
const deleteBillboard = async (req, res, next) => {
  try {
    const billboard = await Billboard.findByPk(req.params.id);

    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    const userId = req.user.userId || req.user.id;
    const isAdmin = req.user.role === 'ADMIN';
    const isOwner = (billboard.ownerId === userId || billboard.createdBy === userId);

    if (!isAdmin && !isOwner) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You do not have permission to delete this billboard.'
      });
    }

    await billboard.destroy();

    return res.json({
      success: true,
      message: 'Billboard deleted successfully.'
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createBillboard,
  getAllBillboards,
  getMyBillboards,
  getBillboardById,
  getBillboardAvailability,
  updateBillboard,
  updateApprovalStatus,
  deleteBillboard
};

