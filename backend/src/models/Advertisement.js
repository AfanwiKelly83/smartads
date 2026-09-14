const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Advertisement = sequelize.define('Advertisement', {
  advertisementId: {
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
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  mediaType: {
    type: DataTypes.ENUM('IMAGE', 'VIDEO'),
    defaultValue: 'IMAGE'
  },
  filePath: {
    type: DataTypes.STRING,
    allowNull: false
  },
  fileSize: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  uploadDate: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  approvalStatus: {
    type: DataTypes.ENUM('PENDING', 'APPROVED', 'REJECTED'),
    defaultValue: 'PENDING'
  },
  verificationNotes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  aiConfidenceScore: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  aiFlaggedReason: {
    type: DataTypes.STRING,
    allowNull: true
  },
  playStartTime: {
    type: DataTypes.STRING,
    allowNull: true
  },
  playEndTime: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true,
  tableName: 'Advertisements'
});

module.exports = Advertisement;
