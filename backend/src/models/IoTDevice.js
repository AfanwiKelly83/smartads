const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const IoTDevice = sequelize.define('IoTDevice', {
  deviceId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  macAddress: {
    type: DataTypes.STRING,
    allowNull: true
  },
  firmwareVersion: {
    type: DataTypes.STRING,
    defaultValue: '1.0.0'
  },
  connectionStatus: {
    type: DataTypes.ENUM('CONNECTED', 'DISCONNECTED', 'WARNING'),
    defaultValue: 'CONNECTED'
  },
  lastSeenAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  billboardId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Billboards',
      key: 'billboardId'
    }
  }
}, {
  timestamps: true,
  tableName: 'IoTDevices'
});

module.exports = IoTDevice;
