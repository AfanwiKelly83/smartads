const { Booking, Billboard } = require('../models');
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

  const toMinutes = (value, fallback) => {
    const match = String(value || fallback).match(/^(\d{1,2}):(\d{2})/);
    return match ? Number(match[1]) * 60 + Number(match[2]) : fallback;
  };

  const reqStart = toMinutes(startTime, 0);
  const reqEnd = toMinutes(endTime, 24 * 60);

  const exactTimeConflicts = overlappingBookings.filter(b => {
    const bStart = toMinutes(b.startTime, 0);
    const bEnd = toMinutes(b.endTime, 24 * 60);
    return reqStart < bEnd && reqEnd > bStart;
  });

  return {
    isAvailable: exactTimeConflicts.length === 0,
    conflictsCount: exactTimeConflicts.length,
    conflicts: exactTimeConflicts
  };
};

const getBillboardTimeSlots = async ({ billboardId, date }) => {
  const billboard = await Billboard.findByPk(billboardId);
  const baseRate = billboard ? (billboard.pricePerHour || 15000.0) : 15000.0;

  const bookings = await Booking.findAll({
    where: {
      billboardId,
      status: { [Op.in]: ['PENDING', 'CONFIRMED'] },
      startDate: { [Op.lte]: date },
      endDate: { [Op.gte]: date }
    },
    attributes: ['bookingId', 'startTime', 'endTime', 'status']
  });

  const toMinutes = (value, fallback) => {
    const match = String(value || fallback).match(/^(\d{1,2}):(\d{2})/);
    return match ? Number(match[1]) * 60 + Number(match[2]) : fallback;
  };

  // Structured time slot template with attributed pricing and tiers
  const slotDefinitions = [
    { startH: 6, startM: 0, endH: 7, endM: 0, label: 'Early Bird (Off-Peak)', tier: 'OFF_PEAK', priceFixed: 2000 },
    { startH: 7, startM: 0, endH: 8, endM: 0, label: 'Morning Commute', tier: 'STANDARD', priceFixed: 3500 },
    { startH: 8, startM: 0, endH: 10, endM: 0, label: 'Morning Prime Rush', tier: 'PRIME', priceFixed: 6000 },
    { startH: 10, startM: 0, endH: 12, endM: 0, label: 'Mid-Day Business', tier: 'STANDARD', priceFixed: 5000 },
    { startH: 12, startM: 0, endH: 14, endM: 0, label: 'Lunch Peak', tier: 'PRIME', priceFixed: 6500 },
    { startH: 14, startM: 0, endH: 16, endM: 0, label: 'Afternoon Broadcast', tier: 'STANDARD', priceFixed: 4500 },
    { startH: 16, startM: 0, endH: 18, endM: 0, label: 'Evening Commute Rush', tier: 'PRIME', priceFixed: 7000 },
    { startH: 18, startM: 0, endH: 20, endM: 0, label: 'Evening Prime Peak', tier: 'MEGA_PRIME', priceFixed: 8000 },
    { startH: 20, startM: 0, endH: 22, endM: 0, label: 'Night Life Prime', tier: 'PRIME', priceFixed: 5000 },
    { startH: 22, startM: 0, endH: 24, endM: 0, label: 'Late Night (Off-Peak)', tier: 'OFF_PEAK', priceFixed: 2500 }
  ];

  return slotDefinitions.map((def, idx) => {
    const startMinutes = def.startH * 60 + def.startM;
    const endMinutes = def.endH * 60 + def.endM;

    const occupied = bookings.find((booking) => {
      const bookingStart = toMinutes(booking.startTime, 0);
      const bookingEnd = toMinutes(booking.endTime, 24 * 60);
      return bookingStart < endMinutes && bookingEnd > startMinutes;
    });

    const formatTime = (hour, minute) => {
      const h24 = hour === 24 ? 0 : hour;
      const suffix = hour >= 12 && hour < 24 ? 'PM' : 'AM';
      const displayHour = h24 % 12 || 12;
      return `${displayHour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')} ${suffix}`;
    };

    const startTimeStr = `${def.startH.toString().padStart(2, '0')}:${def.startM.toString().padStart(2, '0')}`;
    const endTimeStr = `${def.endH === 24 ? '23:59' : def.endH.toString().padStart(2, '0') + ':' + def.endM.toString().padStart(2, '0')}`;
    const timeDisplay = `${formatTime(def.startH, def.startM)} - ${formatTime(def.endH, def.endM)}`;
    const durationHours = (endMinutes - startMinutes) / 60;
    const durationLabel = `${durationHours == durationHours.toFixed(0) ? durationHours.toFixed(0) : durationHours} ${durationHours === 1 ? 'Hour' : 'Hours'}`;

    // Attributed price scaled with billboard pricePerHour
    const calculatedPrice = def.priceFixed ? Math.max(def.priceFixed, Math.round((baseRate * durationHours * 0.4) / 500) * 500) : Math.round(baseRate * durationHours);

    return {
      slotId: `slot_${idx + 1}`,
      time: timeDisplay,
      startTime: startTimeStr,
      endTime: endTimeStr,
      duration: durationLabel,
      label: def.label,
      tier: def.tier,
      price: calculatedPrice,
      isFree: !occupied,
      occupant: occupied ? 'Reserved booking' : null
    };
  });
};

module.exports = {
  checkBillboardAvailability,
  getBillboardTimeSlots
};
