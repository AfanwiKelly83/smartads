const { Booking, Billboard, Campaign, User, Notification, sequelize } = require('../models');
const { checkBillboardAvailability, getBillboardTimeSlots, getBillboardCapacityAvailability } = require('../services/availabilityService');
const { Op } = require('sequelize');

// GET /api/v1/bookings/availability/:billboardId?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD
const getBillboardAvailability = async (req, res, next) => {
  try {
    const { billboardId } = req.params;
    const { startDate, endDate, date } = req.query;

    const queryStart = startDate || date || new Date().toISOString().slice(0, 10);
    const queryEnd = endDate || queryStart;

    const capacityData = await getBillboardCapacityAvailability({
      billboardId: Number(billboardId),
      startDate: queryStart,
      endDate: queryEnd
    });

    const slots = await getBillboardTimeSlots({
      billboardId: Number(billboardId),
      date: queryStart
    });

    return res.json({
      success: true,
      data: {
        ...capacityData,
        slots
      },
      date: queryStart
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/bookings
const createBooking = async (req, res, next) => {
  const transaction = await sequelize.transaction();

  try {
    const { billboardId, campaignId, startDate, endDate, startTime, endTime, repeatOption, amount } = req.body;

    if (!billboardId || !startDate || !endDate) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: 'billboardId, startDate, and endDate are required.'
      });
    }

    const billboard = await Billboard.findByPk(billboardId, { transaction });
    if (!billboard) {
      await transaction.rollback();
      return res.status(404).json({ success: false, message: 'Billboard not found.' });
    }

    // Only approved billboards can be booked
    if (billboard.approvalStatus && billboard.approvalStatus !== 'APPROVED') {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: `This billboard cannot be booked because its approval status is ${billboard.approvalStatus}. Only APPROVED billboards can be booked.`
      });
    }

    // 1. Capacity Check within atomic transaction
    const capacityInfo = await getBillboardCapacityAvailability({
      billboardId: Number(billboardId),
      startDate,
      endDate,
      transaction
    });

    if (!capacityInfo.isAvailable) {
      await transaction.rollback();
      return res.status(409).json({
        success: false,
        message: `Billboard capacity reached for the selected dates (${startDate} to ${endDate}). Maximum ${capacityInfo.maxActiveCampaigns} concurrent campaigns allowed (${capacityInfo.occupiedCampaignsCount} currently active/reserved).`,
        data: {
          maxActiveCampaigns: capacityInfo.maxActiveCampaigns,
          occupiedCampaignsCount: capacityInfo.occupiedCampaignsCount,
          remainingCapacity: 0
        }
      });
    }

    // 2. Micro-slot time conflict check (when specific hourly slots are requested)
    if (startTime && endTime && (startTime !== '00:00' || endTime !== '23:59')) {
      const slotAvailability = await checkBillboardAvailability({
        billboardId,
        startDate,
        endDate,
        startTime,
        endTime
      });

      if (!slotAvailability.isAvailable && (capacityInfo.maxActiveCampaigns === 1 || slotAvailability.conflicts.some(c => c.campaignId === activeCampaignId))) {
        await transaction.rollback();
        return res.status(409).json({
          success: false,
          message: 'Booking conflict: Selected billboard is already reserved during the requested date/time slot.',
          conflictsCount: slotAvailability.conflictsCount
        });
      }
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
      }, { transaction });
      activeCampaignId = autoCampaign.campaignId;
    } else {
      const campaign = await Campaign.findByPk(activeCampaignId, { transaction });
      if (!campaign) {
        await transaction.rollback();
        return res.status(404).json({ success: false, message: 'Campaign not found.' });
      }
    }

    // Calculate total amount
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end - start);
    const totalDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1);
    const hourlyPrice = billboard.pricePerHour || 15000.0;
    const computedAmount = amount ? parseFloat(amount) : (totalDays * (hourlyPrice * 4));

    const booking = await Booking.create({
      advertiserId: userId,
      billboardId,
      campaignId: activeCampaignId,
      startDate,
      endDate,
      startTime: startTime || '00:00',
      endTime: endTime || '23:59',
      repeatOption: repeatOption || 'DAILY',
      status: 'PENDING',
      totalAmount: computedAmount
    }, { transaction });

    await transaction.commit();

    // Notify Billboard Owner of new pending booking
    const ownerId = billboard.ownerId || billboard.createdBy;
    if (ownerId && ownerId !== userId) {
      try {
        await Notification.create({
          userId: ownerId,
          message: `New booking request for your billboard "${billboard.billboardName}" from ${startDate} to ${endDate}. Capacity: ${capacityInfo.occupiedCampaignsCount + 1}/${capacityInfo.maxActiveCampaigns}.`,
          notificationType: 'BOOKING_REQUEST',
          status: 'UNREAD'
        });
      } catch (_) {}
    }

    return res.status(201).json({
      success: true,
      message: 'Booking created successfully. Proceed to payment via DigiPay.',
      data: {
        ...booking.toJSON(),
        remainingCapacity: capacityInfo.remainingCapacity - 1,
        maxActiveCampaigns: capacityInfo.maxActiveCampaigns
      }
    });
  } catch (err) {
    await transaction.rollback();
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
