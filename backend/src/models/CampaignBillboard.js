const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const CampaignBillboard = sequelize.define('CampaignBillboard', {
  campaignId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    allowNull: false,
    references: {
      model: 'Campaigns',
      key: 'campaignId'
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE'
  },
  billboardId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    allowNull: false,
    references: {
      model: 'Billboards',
      key: 'billboardId'
    },
    onUpdate: 'CASCADE',
    onDelete: 'CASCADE'
  }
}, {
  timestamps: true,
  tableName: 'CampaignBillboards'
});

module.exports = CampaignBillboard;
