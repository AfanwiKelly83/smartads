const { Payment, Booking, Campaign, Billboard, Notification, User } = require('../models');
const { processDigiPayPayment } = require('../services/paymentService');
const { Op } = require('sequelize');

// POST /api/v1/payments (Process DigiPay payment for Booking)
const createPayment = async (req, res, next) => {
  try {
    const { bookingId, paymentMethod } = req.body;

    if (!bookingId) {
      return res.status(400).json({ success: false, message: 'bookingId is required.' });
    }

    const booking = await Booking.findByPk(bookingId, {
      include: [{ model: Billboard, as: 'billboard' }]
    });
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.' });
    }

    // Strict Availability Check before processing payment
    const { checkBillboardAvailability } = require('../services/availabilityService');
    const availability = await checkBillboardAvailability({
      billboardId: booking.billboardId,
      startDate: booking.startDate,
      endDate: booking.endDate,
      startTime: booking.startTime,
      endTime: booking.endTime,
      excludeBookingId: booking.bookingId
    });

    if (!availability.isAvailable) {
      return res.status(409).json({
        success: false,
        message: 'Sorry, this time slot is no longer available. It was booked by someone else.'
      });
    }

    // Process via DigiPay Payment Service
    const digiPayResult = await processDigiPayPayment({
      bookingId,
      amount: booking.totalAmount,
      paymentMethod
    });

    const payment = await Payment.create({
      bookingId: booking.bookingId,
      amount: booking.totalAmount,
      paymentMethod: digiPayResult.paymentMethod,
      paymentStatus: digiPayResult.paymentStatus,
      paymentDate: digiPayResult.paymentDate,
      transactionReference: digiPayResult.transactionReference
    });

    // Update Booking status to CONFIRMED upon successful payment
    if (payment.paymentStatus === 'SUCCESSFUL') {
      booking.status = 'CONFIRMED';
      await booking.save();

      // Update associated Campaign status to ACTIVE
      const campaign = await Campaign.findByPk(booking.campaignId);
      if (campaign) {
        campaign.campaignStatus = 'ACTIVE';
        campaign.totalCost = booking.totalAmount;
        await campaign.save();
      }

      // Notify Advertiser
      try {
        await Notification.create({
          userId: booking.advertiserId,
          message: `Payment of ${payment.amount} FCFA via DigiPay was SUCCESSFUL. Booking #${booking.bookingId} is CONFIRMED and Campaign is now ACTIVE.`,
          notificationType: 'PAYMENT',
          status: 'UNREAD'
        });
      } catch (_) {}

      // Notify Billboard Owner of confirmed booking and earnings
      const ownerId = booking.billboard?.ownerId || booking.billboard?.createdBy;
      if (ownerId && ownerId !== booking.advertiserId) {
        try {
          await Notification.create({
            userId: ownerId,
            message: `Booking #${booking.bookingId} confirmed on your billboard "${booking.billboard.billboardName}". Revenue earned: ${payment.amount} FCFA.`,
            notificationType: 'PAYMENT',
            status: 'UNREAD'
          });
        } catch (_) {}
      }
    }

    return res.status(201).json({
      success: true,
      message: 'DigiPay payment processed successfully.',
      data: payment
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/payments/owner-earnings (Owner specific earnings)
const getOwnerEarnings = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.id;

    // 1. Find all billboards owned by this user
    const ownerBillboards = await Billboard.findAll({
      where: { [Op.or]: [{ ownerId: userId }, { createdBy: userId }] },
      attributes: ['billboardId', 'billboardName', 'billboardCode', 'location']
    });
    const billboardIds = ownerBillboards.map(b => b.billboardId);

    if (billboardIds.length === 0) {
      return res.json({
        success: true,
        data: {
          totalEarnings: 0,
          pendingEarnings: 0,
          completedEarnings: 0,
          paymentsCount: 0,
          payments: []
        }
      });
    }

    // 2. Find bookings and payments
    const bookings = await Booking.findAll({
      where: { billboardId: { [Op.in]: billboardIds } },
      include: [
        { model: Payment, as: 'payment' },
        { model: Billboard, as: 'billboard', attributes: ['billboardId', 'billboardName', 'billboardCode'] },
        { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }
      ]
    });

    let totalEarnings = 0;
    let pendingEarnings = 0;
    let completedEarnings = 0;
    const paymentsList = [];

    bookings.forEach(b => {
      if (b.payment && b.payment.paymentStatus === 'SUCCESSFUL') {
        totalEarnings += Number(b.payment.amount || 0);
        completedEarnings += Number(b.payment.amount || 0);
        paymentsList.push({
          paymentId: b.payment.paymentId,
          amount: b.payment.amount,
          paymentMethod: b.payment.paymentMethod,
          paymentStatus: b.payment.paymentStatus,
          paymentDate: b.payment.paymentDate,
          transactionReference: b.payment.transactionReference,
          billboard: b.billboard,
          advertiser: b.advertiser,
          bookingId: b.bookingId
        });
      } else if (b.status === 'PENDING') {
        pendingEarnings += Number(b.totalAmount || 0);
      }
    });

    return res.json({
      success: true,
      data: {
        totalEarnings,
        pendingEarnings,
        completedEarnings,
        paymentsCount: paymentsList.length,
        payments: paymentsList
      }
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/payments (Admin global payments or Owner billboard payments)
const getAllPayments = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.id;
    const role = req.user.role;

    if (role === 'BILLBOARD_OWNER') {
      return getOwnerEarnings(req, res, next);
    }

    const payments = await Payment.findAll({
      include: [
        {
          model: Booking,
          as: 'booking',
          include: [
            { model: Billboard, as: 'billboard' },
            { model: User, as: 'advertiser', attributes: ['userId', 'fullName', 'email'] }
          ]
        }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: payments
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createPayment,
  getOwnerEarnings,
  getAllPayments
};
