const { Billboard, User } = require('../models');
const { generateBillboardQRCode } = require('../services/qrCodeService');

// POST /api/v1/billboards (Only ADMIN allowed)
const createBillboard = async (req, res, next) => {
  try {
    const { billboardName, location, pricePerHour, latitude, longitude, screenSize, resolution } = req.body;

    if (!billboardName || !location) {
      return res.status(400).json({
        success: false,
        message: 'billboardName and location are required.'
      });
    }

    const billboard = await Billboard.create({
      billboardName,
      location,
      pricePerHour: pricePerHour || 10.0,
      latitude,
      longitude,
      screenSize,
      resolution: resolution || '1920x1080',
      displayStatus: 'ACTIVE',
      availabilityStatus: 'AVAILABLE',
      createdBy: req.user.userId || req.user.id
    });

    // Automatically generate QR Code
    const qrCodePath = await generateBillboardQRCode(billboard);
    billboard.qrCode = qrCodePath;
    await billboard.save();

    return res.status(201).json({
      success: true,
      message: 'Billboard created successfully and QR code generated.',
      data: billboard
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/billboards
const getAllBillboards = async (req, res, next) => {
  try {
    const billboards = await Billboard.findAll({
      include: [{ model: User, as: 'creator', attributes: ['userId', 'fullName', 'email'] }]
    });

    return res.json({
      success: true,
      data: billboards
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/billboards/:id
const getBillboardById = async (req, res, next) => {
  try {
    const billboard = await Billboard.findByPk(req.params.id, {
      include: [{ model: User, as: 'creator', attributes: ['userId', 'fullName', 'email'] }]
    });

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

// PUT /api/v1/billboards/:id (Admin only)
const updateBillboard = async (req, res, next) => {
  try {
    const billboard = await Billboard.findByPk(req.params.id);

    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    const { billboardName, location, pricePerHour, displayStatus, availabilityStatus, latitude, longitude, screenSize, resolution } = req.body;

    if (billboardName) billboard.billboardName = billboardName;
    if (location) billboard.location = location;
    if (pricePerHour !== undefined) billboard.pricePerHour = pricePerHour;
    if (displayStatus) billboard.displayStatus = displayStatus;
    if (availabilityStatus) billboard.availabilityStatus = availabilityStatus;
    if (latitude !== undefined) billboard.latitude = latitude;
    if (longitude !== undefined) billboard.longitude = longitude;
    if (screenSize) billboard.screenSize = screenSize;
    if (resolution) billboard.resolution = resolution;

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

// DELETE /api/v1/billboards/:id (Admin only)
const deleteBillboard = async (req, res, next) => {
  try {
    const billboard = await Billboard.findByPk(req.params.id);

    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
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
  getBillboardById,
  updateBillboard,
  deleteBillboard
};
