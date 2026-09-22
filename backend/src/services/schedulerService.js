const { Billboard, Campaign, Booking, Advertisement, sequelize } = require('../models');
const { Op } = require('sequelize');

/**
 * Smart Scheduler Service
 * Calculates dynamic shared playlist rotation for digital billboard display players
 * Preserves media duration (e.g., 5s, 15s, 30s, 60s) in a fair round-robin cycle.
 */
const getActivePlaylistForBillboard = async (billboardId) => {
  const currentDate = new Date().toISOString().split('T')[0];

  const billboard = await Billboard.findByPk(billboardId);
  if (!billboard) {
    throw new Error('Billboard not found');
  }

  // Find confirmed active bookings on this billboard within today's date range
  const activeBookings = await Booking.findAll({
    where: {
      billboardId,
      status: { [Op.in]: ['CONFIRMED', 'PAID'] },
      startDate: { [Op.lte]: currentDate },
      endDate: { [Op.gte]: currentDate }
    },
    include: [
      {
        model: Campaign,
        as: 'campaign',
        required: false
      }
    ],
    order: [['bookingId', 'ASC']]
  });

  const playlist = [];

  for (let i = 0; i < activeBookings.length; i++) {
    const booking = activeBookings[i];
    
    // Find approved advertisement for this campaign or advertiser
    let ad = await Advertisement.findOne({
      where: {
        advertiserId: booking.advertiserId,
        approvalStatus: { [Op.in]: ['APPROVED', 'AI_APPROVED'] }
      },
      order: [['updatedAt', 'DESC']]
    });

    const durationSeconds = (ad && ad.fileSize && ad.mediaType === 'VIDEO') 
      ? Math.min(60, Math.max(5, Math.round(ad.fileSize / (1024 * 1024) * 5))) 
      : 15;

    const mediaUrl = ad ? (ad.filePath || `/uploads/${ad.advertisementId}`) : '/uploads/default-placeholder.mp4';
    const mediaType = ad ? (ad.mediaType || 'VIDEO') : 'IMAGE';
    const adTitle = ad ? ad.title : (booking.campaign ? `Campaign #${booking.campaignId}` : `Booking #${booking.bookingId}`);
    const adId = ad ? ad.advertisementId : booking.bookingId;

    playlist.push({
      slotOrder: i + 1,
      bookingId: booking.bookingId,
      campaignId: booking.campaignId,
      campaignName: booking.campaign ? (booking.campaign.campaignType || 'STANDARD') : 'Standard Campaign',
      advertisementId: adId,
      adTitle,
      mediaUrl,
      mediaType,
      durationSeconds,
      startDate: booking.startDate,
      endDate: booking.endDate,
      startTime: booking.startTime || '00:00',
      endTime: booking.endTime || '23:59'
    });
  }

  const cycleDurationSeconds = playlist.reduce((total, item) => total + item.durationSeconds, 0);

  return {
    billboardId: Number(billboardId),
    billboardName: billboard.billboardName,
    maxActiveCampaigns: billboard.maxActiveCampaigns || 10,
    timestamp: new Date().toISOString(),
    activeCampaignsCount: playlist.length,
    cycleDurationSeconds,
    rotationMode: 'FAIR_ROUND_ROBIN',
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
