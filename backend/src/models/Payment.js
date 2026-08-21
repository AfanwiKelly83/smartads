const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Payment = sequelize.define('Payment', {
  paymentId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  bookingId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Bookings',
      key: 'bookingId'
    }
  },
  amount: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  paymentMethod: {
    type: DataTypes.STRING,
    defaultValue: 'DIGIPAY'
  },
  paymentStatus: {
    type: DataTypes.ENUM('PENDING', 'SUCCESSFUL', 'FAILED', 'CANCELLED'),
    defaultValue: 'PENDING'
  },
  paymentDate: {
    type: DataTypes.DATE,
    allowNull: true
  },
  transactionReference: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false
  }
}, {
  timestamps: true,
  tableName: 'Payments'
});

module.exports = Payment;
