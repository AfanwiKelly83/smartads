const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Campaign = sequelize.define('Campaign', {
  campaignId: {
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
  campaignType: {
    type: DataTypes.STRING,
    defaultValue: 'STANDARD'
  },
  startDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  endDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  repeatOption: {
    type: DataTypes.STRING,
    defaultValue: 'DAILY'
  },
  campaignStatus: {
    type: DataTypes.ENUM('DRAFT', 'PENDING_PAYMENT', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED'),
    defaultValue: 'DRAFT'
  },
  totalCost: {
    type: DataTypes.FLOAT,
    defaultValue: 0.0
  }
}, {
  timestamps: true,
  tableName: 'Campaigns'
});

module.exports = Campaign;
