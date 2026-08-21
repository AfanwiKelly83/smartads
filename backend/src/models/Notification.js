const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Notification = sequelize.define('Notification', {
  notificationId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'userId'
    }
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  notificationType: {
    type: DataTypes.STRING,
    defaultValue: 'SYSTEM'
  },
  status: {
    type: DataTypes.ENUM('UNREAD', 'READ'),
    defaultValue: 'UNREAD'
  }
}, {
  timestamps: true,
  tableName: 'Notifications'
});

module.exports = Notification;
