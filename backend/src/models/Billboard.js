const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Billboard = sequelize.define('Billboard', {
  billboardId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  billboardName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  location: {
    type: DataTypes.STRING,
    allowNull: false
  },
  qrCode: {
    type: DataTypes.STRING,
    allowNull: true
  },
  displayStatus: {
    type: DataTypes.ENUM('ACTIVE', 'INACTIVE', 'MAINTENANCE'),
    defaultValue: 'ACTIVE'
  },
  availabilityStatus: {
    type: DataTypes.ENUM('AVAILABLE', 'BOOKED', 'UNAVAILABLE'),
    defaultValue: 'AVAILABLE'
  },
  pricePerHour: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 10.0
  },
  createdBy: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'userId'
    }
  },
  latitude: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  longitude: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  screenSize: {
    type: DataTypes.STRING,
    allowNull: true
  },
  resolution: {
    type: DataTypes.STRING,
    defaultValue: '1920x1080'
  }
}, {
  timestamps: true,
  tableName: 'Billboards'
});

module.exports = Billboard;
