const { Billboard, Campaign, Booking, Advertisement, sequelize } = require('../models');
const { Op } = require('sequelize');

/**
 * Smart Scheduler Service
 * Calculates dynamic playback rotation for digital billboard display players
 */
const getActivePlaylistForBillboard = async (billboardId) => {
  const currentDate = new Date().toISOString().split('T')[0];
  const currentTime = new Date().toTimeString().slice(0, 5); // "HH:MM"

  // Find active bookings on this billboard
  const activeBookings = await Booking.findAll({
    where: {
      billboardId,
      status: 'CONFIRMED',
      startDate: { [Op.lte]: currentDate },
      endDate: { [Op.gte]: currentDate }
    },
    include: [
      {
        model: Campaign,
        as: 'campaign',
        where: { status: 'ACTIVE' },
        include: [
          {
            model: Advertisement,
            as: 'advertisement',
            where: { verificationStatus: 'APPROVED' }
          }
        ]
      }
    ]
  });

  const playlist = activeBookings.map((booking) => {
    const campaign = booking.campaign;
    const ad = campaign.advertisement;
    return {
      bookingId: booking.id,
      campaignId: campaign.id,
      campaignName: campaign.name,
      adId: ad.id,
      adTitle: ad.title,
      mediaUrl: ad.mediaUrl,
      mediaType: ad.mediaType,
      durationSeconds: ad.durationSeconds || 15,
      startTime: booking.startTime,
      endTime: booking.endTime
    };
  });

  return {
    billboardId,
    timestamp: new Date().toISOString(),
    totalAds: playlist.length,
    playlist
  };
};

/**
 * Background worker to complete expired campaigns
 */
const checkExpiredCampaigns = async () => {
  const today = new Date().toISOString().split('T')[0];

  try {
    const [updatedCount] = await Campaign.update(
      { status: 'COMPLETED' },
      {
        where: {
          status: 'ACTIVE',
          endDate: { [Op.lt]: today }
        }
      }
    );

    if (updatedCount > 0) {
      console.log(`[Scheduler] Auto-completed ${updatedCount} expired campaigns.`);
    }
  } catch (err) {
    console.error('[Scheduler Error]', err.message);
  }
};

module.exports = {
  getActivePlaylistForBillboard,
  checkExpiredCampaigns
};
