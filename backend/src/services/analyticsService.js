const { User, Billboard, Campaign, Booking, Payment } = require('../models');

/**
 * Analytics Service - Calculates real-time system statistics from database records
 */
const calculateSystemStatistics = async () => {
  const totalUsers = await User.count();
  const totalAdvertisers = await User.count({ where: { role: 'ADVERTISER' } });
  const totalAdmins = await User.count({ where: { role: 'ADMIN' } });

  const totalBillboards = await Billboard.count();
  const availableBillboards = await Billboard.count({ where: { availabilityStatus: 'AVAILABLE' } });
  const activeBillboards = await Billboard.count({ where: { displayStatus: 'ACTIVE' } });

  const activeCampaigns = await Campaign.count({ where: { campaignStatus: 'ACTIVE' } });
  const totalBookings = await Booking.count();
  const confirmedBookings = await Booking.count({ where: { status: 'CONFIRMED' } });

  const successfulPayments = await Payment.findAll({ where: { paymentStatus: 'SUCCESSFUL' } });
  const totalRevenue = successfulPayments.reduce((acc, p) => acc + (p.amount || 0), 0);

  return {
    users: {
      total: totalUsers,
      advertisers: totalAdvertisers,
      admins: totalAdmins
    },
    billboards: {
      total: totalBillboards,
      available: availableBillboards,
      activeDisplay: activeBillboards
    },
    campaigns: {
      active: activeCampaigns
    },
    bookings: {
      total: totalBookings,
      confirmed: confirmedBookings
    },
    financials: {
      totalRevenue: parseFloat(totalRevenue.toFixed(2)),
      currency: 'XAF'
    }
  };
};

module.exports = {
  calculateSystemStatistics
};
