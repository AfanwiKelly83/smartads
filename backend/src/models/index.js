const sequelize = require('../config/database');
const User = require('./User');
const Billboard = require('./Billboard');
const Advertisement = require('./Advertisement');
const Campaign = require('./Campaign');
const CampaignBillboard = require('./CampaignBillboard');
const Booking = require('./Booking');
const Payment = require('./Payment');
const Notification = require('./Notification');
const IoTDevice = require('./IoTDevice');
const PlaybackLog = require('./PlaybackLog');

// 1. User -> Advertisement (1 : 0..*)
User.hasMany(Advertisement, { foreignKey: 'advertiserId', sourceKey: 'userId', as: 'advertisements' });
Advertisement.belongsTo(User, { foreignKey: 'advertiserId', targetKey: 'userId', as: 'advertiser' });

// 2. User -> Campaign (1 : 0..*)
User.hasMany(Campaign, { foreignKey: 'advertiserId', sourceKey: 'userId', as: 'campaigns' });
Campaign.belongsTo(User, { foreignKey: 'advertiserId', targetKey: 'userId', as: 'advertiser' });

// 3. User -> Booking (1 : 0..*)
User.hasMany(Booking, { foreignKey: 'advertiserId', sourceKey: 'userId', as: 'bookings' });
Booking.belongsTo(User, { foreignKey: 'advertiserId', targetKey: 'userId', as: 'advertiser' });

// 4. User -> Notification (1 : 0..*)
User.hasMany(Notification, { foreignKey: 'userId', sourceKey: 'userId', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'userId', targetKey: 'userId', as: 'user' });

// 5. User -> Billboard (1 : 0..* Admin creator)
User.hasMany(Billboard, { foreignKey: 'createdBy', sourceKey: 'userId', as: 'createdBillboards' });
Billboard.belongsTo(User, { foreignKey: 'createdBy', targetKey: 'userId', as: 'creator' });

// 6. Billboard -> Booking (1 : 0..*)
Billboard.hasMany(Booking, { foreignKey: 'billboardId', sourceKey: 'billboardId', as: 'bookings' });
Booking.belongsTo(Billboard, { foreignKey: 'billboardId', targetKey: 'billboardId', as: 'billboard' });

// 7. Campaign -> Booking (1 : 0..*)
Campaign.hasMany(Booking, { foreignKey: 'campaignId', sourceKey: 'campaignId', as: 'bookings' });
Booking.belongsTo(Campaign, { foreignKey: 'campaignId', targetKey: 'campaignId', as: 'campaign' });

// 8. Booking -> Payment (1 : 0..1)
Booking.hasOne(Payment, { foreignKey: 'bookingId', sourceKey: 'bookingId', as: 'payment' });
Payment.belongsTo(Booking, { foreignKey: 'bookingId', targetKey: 'bookingId', as: 'booking' });

// 9. Campaign <-> Billboard (Many-to-Many through CampaignBillboard)
Campaign.belongsToMany(Billboard, {
  through: CampaignBillboard,
  foreignKey: 'campaignId',
  otherKey: 'billboardId',
  sourceKey: 'campaignId',
  targetKey: 'billboardId',
  as: 'billboards'
});
Billboard.belongsToMany(Campaign, {
  through: CampaignBillboard,
  foreignKey: 'billboardId',
  otherKey: 'campaignId',
  sourceKey: 'billboardId',
  targetKey: 'campaignId',
  as: 'campaigns'
});

// 10. Billboard -> IoTDevice (1 : 0..1)
Billboard.hasOne(IoTDevice, { foreignKey: 'billboardId', sourceKey: 'billboardId', as: 'iotDevice' });
IoTDevice.belongsTo(Billboard, { foreignKey: 'billboardId', targetKey: 'billboardId', as: 'billboard' });

// 11. PlaybackLog Associations
Billboard.hasMany(PlaybackLog, { foreignKey: 'billboardId', sourceKey: 'billboardId', as: 'playbackLogs' });
PlaybackLog.belongsTo(Billboard, { foreignKey: 'billboardId', targetKey: 'billboardId', as: 'billboard' });

Advertisement.hasMany(PlaybackLog, { foreignKey: 'advertisementId', sourceKey: 'advertisementId', as: 'playbackLogs' });
PlaybackLog.belongsTo(Advertisement, { foreignKey: 'advertisementId', targetKey: 'advertisementId', as: 'advertisement' });

Campaign.hasMany(PlaybackLog, { foreignKey: 'campaignId', sourceKey: 'campaignId', as: 'playbackLogs' });
PlaybackLog.belongsTo(Campaign, { foreignKey: 'campaignId', targetKey: 'campaignId', as: 'campaign' });

module.exports = {
  sequelize,
  User,
  Billboard,
  Advertisement,
  Campaign,
  CampaignBillboard,
  Booking,
  Payment,
  Notification,
  IoTDevice,
  PlaybackLog
};
