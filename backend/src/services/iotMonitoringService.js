const { DeviceHeartbeat, Billboard, sequelize } = require('../models');
const { Op } = require('sequelize');

/**
 * IoT Monitoring Service - checks device health and flags inactive billboards as OFFLINE
 */
const checkDeviceHealth = async () => {
  try {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

    // Find heartbeats older than 5 mins
    const offlineHeartbeats = await DeviceHeartbeat.findAll({
      where: {
        lastSeen: { [Op.lt]: fiveMinutesAgo },
        status: 'ONLINE'
      }
    });

    for (const hb of offlineHeartbeats) {
      hb.status = 'OFFLINE';
      await hb.save();

      // Update associated billboard status
      await Billboard.update(
        { status: 'OFFLINE' },
        { where: { id: hb.billboardId } }
      );
    }
  } catch (err) {
    console.error('[IoT Health Service Error]', err.message);
  }
};

module.exports = {
  checkDeviceHealth
};
