const { Booking } = require('../models');
const { Op } = require('sequelize');

/**
 * Service to check date/time availability & overlap for a billboard
 */
const checkBillboardAvailability = async ({ billboardId, startDate, endDate, startTime, endTime, excludeBookingId }) => {
  const whereClause = {
    billboardId,
    status: { [Op.in]: ['PENDING', 'CONFIRMED'] },
    [Op.or]: [
      {
        startDate: { [Op.lte]: endDate },
        endDate: { [Op.gte]: startDate }
      }
    ]
  };

  if (excludeBookingId) {
    whereClause.bookingId = { [Op.ne]: excludeBookingId };
  }

  const overlappingBookings = await Booking.findAll({
    where: whereClause
  });

  return {
    isAvailable: overlappingBookings.length === 0,
    conflictsCount: overlappingBookings.length,
    conflicts: overlappingBookings
  };
};

const getBillboardTimeSlots = async ({ billboardId, date }) => {
  const bookings = await Booking.findAll({
    where: {
      billboardId,
      status: { [Op.in]: ['PENDING', 'CONFIRMED'] },
      startDate: { [Op.lte]: date },
      endDate: { [Op.gte]: date }
    },
    attributes: ['startTime', 'endTime']
  });

  const toMinutes = (value, fallback) => {
    const match = String(value || fallback).match(/^(\d{1,2}):(\d{2})/);
    return match ? Number(match[1]) * 60 + Number(match[2]) : fallback;
  };

  return Array.from({ length: 12 }, (_, index) => {
    const startMinutes = (8 + index) * 60;
    const endMinutes = startMinutes + 60;
    const occupied = bookings.find((booking) => {
      const bookingStart = toMinutes(booking.startTime, 0);
      const bookingEnd = toMinutes(booking.endTime, 24 * 60);
      return bookingStart < endMinutes && bookingEnd > startMinutes;
    });
    const formatTime = (minutes) => {
      const hour = Math.floor(minutes / 60);
      const suffix = hour >= 12 ? 'PM' : 'AM';
      const displayHour = hour % 12 || 12;
      return `${displayHour.toString().padStart(2, '0')}:00 ${suffix}`;
    };

    return {
      time: `${formatTime(startMinutes)} - ${formatTime(endMinutes)}`,
      isFree: !occupied,
      occupant: occupied ? 'Reserved booking' : null
    };
  });
};

module.exports = {
  checkBillboardAvailability,
  getBillboardTimeSlots
};
