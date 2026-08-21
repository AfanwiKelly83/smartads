const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Booking = sequelize.define('Booking', {
  bookingId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  advertiserId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'userId'
    }
  },
  billboardId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Billboards',
      key: 'billboardId'
    }
  },
  campaignId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Campaigns',
      key: 'campaignId'
    }
  },
  startDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  endDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  startTime: {
    type: DataTypes.STRING,
    defaultValue: '00:00'
  },
  endTime: {
    type: DataTypes.STRING,
    defaultValue: '23:59'
  },
  repeatOption: {
    type: DataTypes.STRING,
    defaultValue: 'DAILY'
  },
  status: {
    type: DataTypes.ENUM('PENDING', 'CONFIRMED', 'REJECTED', 'EXPIRED'),
    defaultValue: 'PENDING'
  },
  totalAmount: {
    type: DataTypes.FLOAT,
    defaultValue: 0.0
  }
}, {
  timestamps: true,
  tableName: 'Bookings'
});

module.exports = Booking;
