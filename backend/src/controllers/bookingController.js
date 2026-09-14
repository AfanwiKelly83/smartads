const { Booking, Billboard, Campaign, User } = require('../models');
const { checkBillboardAvailability, getBillboardTimeSlots } = require('../services/availabilityService');

// GET /api/v1/bookings/availability/:billboardId?date=YYYY-MM-DD
const getBillboardAvailability = async (req, res, next) => {
  try {
    const date = req.query.date || new Date().toISOString().slice(0, 10);
    const slots = await getBillboardTimeSlots({
      billboardId: Number(req.params.billboardId),
      date
    });
    return res.json({ success: true, data: slots, date });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/bookings
const createBooking = async (req, res, next) => {
  try {
    const { billboardId, campaignId, startDate, endDate, startTime, endTime, repeatOption } = req.body;

    if (!billboardId || !campaignId || !startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'billboardId, campaignId, startDate, and endDate are required.'
      });
    }

    const billboard = await Billboard.findByPk(billboardId);
    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    const campaign = await Campaign.findByPk(campaignId);
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    // Availability Overlap Check
    const availability = await checkBillboardAvailability({
      billboardId,
      startDate,
      endDate,
      startTime,
      endTime
    });

    if (!availability.isAvailable) {
      return res.status(409).json({
        success: false,
        message: 'Booking conflict: Selected billboard is already reserved during the requested date/time slot.',
        conflictsCount: availability.conflictsCount
      });
    }

    // Calculate total amount
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end - start);
    const totalDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
    const totalAmount = totalDays * (billboard.pricePerHour * 10); // Standard daily slot price

    const booking = await Booking.create({
      advertiserId: req.user.userId || req.user.id,
      billboardId,
      campaignId,
      startDate,
      endDate,
      startTime: startTime || '08:00',
      endTime: endTime || '20:00',
      repeatOption: repeatOption || 'DAILY',
      status: 'PENDING',
      totalAmount
    });

    return res.status(201).json({
      success: true,
      message: 'Booking created successfully. Proceed to payment via DigiPay.',
      data: booking
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/bookings
const getAllBookings = async (req, res, next) => {
  try {
    let whereClause = {};
    if (req.user.role !== 'ADMIN') {
      whereClause.advertiserId = req.user.userId || req.user.id;
    }

    const bookings = await Booking.findAll({
      where: whereClause,
      include: [
        { model: Billboard, as: 'billboard' },
        { model: Campaign, as: 'campaign' },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }
      ]
    });

    return res.json({
      success: true,
      data: bookings
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/bookings/:id
const getBookingById = async (req, res, next) => {
  try {
    const booking = await Booking.findByPk(req.params.id, {
      include: [
        { model: Billboard, as: 'billboard' },
        { model: Campaign, as: 'campaign' },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }
      ]
    });

    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.' });
    }

    return res.json({
      success: true,
      data: booking
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createBooking,
  getAllBookings,
  getBookingById,
  getBillboardAvailability
};
