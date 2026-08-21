const { IoTDevice, Billboard } = require('../models');

/**
 * Isolated IoT Hardware Device Management Service
 */
const registerDeviceHeartbeat = async ({ billboardId, macAddress, firmwareVersion, connectionStatus }) => {
  let device = await IoTDevice.findOne({ where: { billboardId } });

  if (device) {
    device.macAddress = macAddress || device.macAddress;
    device.firmwareVersion = firmwareVersion || device.firmwareVersion;
    device.connectionStatus = connectionStatus || 'CONNECTED';
    device.lastSeenAt = new Date();
    await device.save();
  } else {
    device = await IoTDevice.create({
      billboardId,
      macAddress: macAddress || '00:1B:44:11:3A:B7',
      firmwareVersion: firmwareVersion || '1.0.0',
      connectionStatus: connectionStatus || 'CONNECTED',
      lastSeenAt: new Date()
    });
  }

  return device;
};

module.exports = {
  registerDeviceHeartbeat
};
