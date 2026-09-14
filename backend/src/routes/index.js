const express = require('express');
const router = express.Router();

const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const billboardRoutes = require('./billboardRoutes');
const advertisementRoutes = require('./advertisementRoutes');
const campaignRoutes = require('./campaignRoutes');
const bookingRoutes = require('./bookingRoutes');
const paymentRoutes = require('./paymentRoutes');
const notificationRoutes = require('./notificationRoutes');
const analyticsRoutes = require('./analyticsRoutes');
const iotRoutes = require('./iotRoutes');

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/billboards', billboardRoutes);
router.use('/advertisements', advertisementRoutes);
router.use('/campaigns', campaignRoutes);
router.use('/bookings', bookingRoutes);
router.use('/payments', paymentRoutes);
router.use('/notifications', notificationRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/iot', iotRoutes);

module.exports = router;
