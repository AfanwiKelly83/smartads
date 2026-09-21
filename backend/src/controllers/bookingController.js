const { Booking, Billboard, Campaign, User, Notification } = require('../models');
const { checkBillboardAvailability, getBillboardTimeSlots } = require('../services/availabilityService');
const { Op } = require('sequelize');

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

    if (!billboardId || !startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'billboardId, startDate, and endDate are required.'
      });
    }

    const billboard = await Billboard.findByPk(billboardId);
    if (!billboard) {
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    // Only approved billboards can be booked
    if (billboard.approvalStatus && billboard.approvalStatus !== 'APPROVED') {
      return res.status(400).json({
        success: false,
        message: `This billboard cannot be booked because its approval status is ${billboard.approvalStatus}. Only APPROVED billboards can be booked.`
      });
    }

    const userId = req.user.userId || req.user.id;

    // Auto-create Campaign if not provided
    let activeCampaignId = campaignId;
    if (!activeCampaignId) {
      const autoCampaign = await Campaign.create({
        advertiserId: userId,
        campaignType: 'STANDARD',
        startDate,
        endDate,
        repeatOption: repeatOption || 'DAILY',
        campaignStatus: 'PENDING_PAYMENT',
        totalCost: 0
      });
      activeCampaignId = autoCampaign.campaignId;
    } else {
      const campaign = await Campaign.findByPk(activeCampaignId);
      if (!campaign) {
        return res.status(404).json({ success: false, message: 'Campaign not found.' });
      }
    }

    // Availability Overlap Check (prevent double booking)
    const availability = await checkBillboardAvailability({
      billboardId,
      startDate,
      endDate,
      startTime: startTime || '08:00',
      endTime: endTime || '20:00'
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
    const hourlyPrice = billboard.pricePerHour || 15000.0;
    const totalAmount = totalDays * (hourlyPrice * 4); // Standard slot rate

    const booking = await Booking.create({
      advertiserId: userId,
      billboardId,
      campaignId: activeCampaignId,
      startDate,
      endDate,
      startTime: startTime || '08:00',
      endTime: endTime || '20:00',
      repeatOption: repeatOption || 'DAILY',
      status: 'PENDING',
      totalAmount
    });

    // Notify Billboard Owner of new pending booking
    const ownerId = billboard.ownerId || billboard.createdBy;
    if (ownerId && ownerId !== userId) {
      try {
        await Notification.create({
          userId: ownerId,
          message: `New booking request for your billboard "${billboard.billboardName}" on ${startDate} (${startTime || '08:00'} - ${endTime || '20:00'}).`,
          notificationType: 'BOOKING_REQUEST',
          status: 'UNREAD'
        });
      } catch (_) {}
    }

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
    const userId = req.user.userId || req.user.id;
    const role = req.user.role;

    let whereClause = {};

    if (role === 'BILLBOARD_OWNER') {
      const ownerBillboards = await Billboard.findAll({
        where: { [Op.or]: [{ ownerId: userId }, { createdBy: userId }] },
        attributes: ['billboardId']
      });
      const ids = ownerBillboards.map(b => b.billboardId);
      whereClause = { billboardId: { [Op.in]: ids } };
    } else if (role !== 'ADMIN') {
      whereClause.advertiserId = userId;
    }

    const bookings = await Booking.findAll({
      where: whereClause,
      include: [
        { model: Billboard, as: 'billboard' },
        { model: Campaign, as: 'campaign' },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: bookings
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/bookings/owner-bookings (Bookings for Billboard Owner's billboards)
const getOwnerBookings = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.id;

    const ownerBillboards = await Billboard.findAll({
      where: { [Op.or]: [{ ownerId: userId }, { createdBy: userId }] },
      attributes: ['billboardId']
    });
    const ids = ownerBillboards.map(b => b.billboardId);

    const bookings = await Booking.findAll({
      where: { billboardId: { [Op.in]: ids } },
      include: [
        { model: Billboard, as: 'billboard' },
        { model: Campaign, as: 'campaign' },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] }
      ],
      order: [['createdAt', 'DESC']]
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
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email', 'phoneNumber'] }
      ]
    });

    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.' });
    }

    const userId = req.user.userId || req.user.id;
    const role = req.user.role;
    const isAdvertiser = booking.advertiserId === userId;
    const isOwner = booking.billboard && (booking.billboard.ownerId === userId || booking.billboard.createdBy === userId);

    if (role !== 'ADMIN' && !isAdvertiser && !isOwner) {
      return res.status(403).json({ success: false, message: 'Forbidden: Access to this booking is denied.' });
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
  getOwnerBookings,
  getBookingById,
  getBillboardAvailability
};
