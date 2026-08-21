const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const PlaybackLog = sequelize.define('PlaybackLog', {
  logId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  billboardId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Billboards',
      key: 'billboardId'
    }
  },
  advertisementId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Advertisements',
      key: 'advertisementId'
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
  playedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  durationPlayed: {
    type: DataTypes.INTEGER,
    defaultValue: 15
  },
  status: {
    type: DataTypes.ENUM('SUCCESS', 'INTERRUPTED', 'ERROR'),
    defaultValue: 'SUCCESS'
  }
}, {
  timestamps: true,
  tableName: 'PlaybackLogs'
});

module.exports = PlaybackLog;
