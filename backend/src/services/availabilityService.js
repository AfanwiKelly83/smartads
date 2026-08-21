const { Booking } = require('../models');
const { Op } = require('sequelize');

/**
 * Service to check date/time availability & overlap for a billboard
 */
const checkBillboardAvailability = async ({ billboardId, startDate, endDate, startTime, endTime }) => {
  const overlappingBookings = await Booking.findAll({
    where: {
      billboardId,
      status: { [Op.in]: ['PENDING', 'CONFIRMED'] },
      [Op.or]: [
        {
          startDate: { [Op.lte]: endDate },
          endDate: { [Op.gte]: startDate }
        }
      ]
    }
  });

  return {
    isAvailable: overlappingBookings.length === 0,
    conflictsCount: overlappingBookings.length,
    conflicts: overlappingBookings
  };
};

module.exports = {
  checkBillboardAvailability
};
