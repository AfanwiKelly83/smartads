const { IoTDevice, Billboard } = require('../models');
const { registerDeviceHeartbeat } = require('../services/iotService');
const { Op } = require('sequelize');

// POST /api/v1/iot/heartbeat
const postHeartbeat = async (req, res, next) => {
  try {
    const { billboardId, macAddress, firmwareVersion, connectionStatus } = req.body;

    if (!billboardId) {
      return res.status(400).json({ success: false, message: 'billboardId is required.' });
    }

    const device = await registerDeviceHeartbeat({
      billboardId,
      macAddress,
      firmwareVersion,
      connectionStatus
    });

    return res.json({
      success: true,
      message: 'IoT Device heartbeat recorded.',
      data: device
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/iot/devices
const getDevices = async (req, res, next) => {
  try {
    const userId = req.user?.userId || req.user?.id;
    const role = req.user?.role;

    let billboardWhere = {};
    if (role === 'BILLBOARD_OWNER') {
      billboardWhere = {
        [Op.or]: [{ ownerId: userId }, { createdBy: userId }]
      };
    }

    const isOwner = role === 'BILLBOARD_OWNER';
    const devices = await IoTDevice.findAll({
      include: [
        {
          model: Billboard,
          as: 'billboard',
          where: isOwner ? billboardWhere : undefined,
          required: isOwner ? true : false
        }
      ]
    });

    return res.json({
      success: true,
      data: devices
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  postHeartbeat,
  getDevices
};
