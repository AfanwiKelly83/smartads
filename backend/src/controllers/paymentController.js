const { Payment, Booking, Campaign, Notification } = require('../models');
const { processDigiPayPayment } = require('../services/paymentService');

// POST /api/v1/payments (Process DigiPay payment for Booking)
const createPayment = async (req, res, next) => {
  try {
    const { bookingId, paymentMethod } = req.body;

    if (!bookingId) {
      return res.status(400).json({ success: false, message: 'bookingId is required.' });
    }

    const booking = await Booking.findByPk(bookingId);
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

    // Check if there is another CONFIRMED booking that conflicts
    // The checkBillboardAvailability service counts overlapping bookings.
    // However, we only care if they are already CONFIRMED or ACTIVE.
    // Let's assume the service does that. If not available, abort payment.
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
        await campaign.save();
      }

      // Notify Advertiser
      await Notification.create({
        userId: booking.advertiserId,
        message: `Payment of ${payment.amount} via DigiPay was SUCCESSFUL. Booking #${booking.bookingId} is now CONFIRMED.`,
        notificationType: 'PAYMENT',
        status: 'UNREAD'
      });
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

// GET /api/v1/payments
const getAllPayments = async (req, res, next) => {
  try {
    const payments = await Payment.findAll({
      include: [{ model: Booking, as: 'booking' }]
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
  getAllPayments
};
