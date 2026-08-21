const { Notification } = require('../models');

// GET /api/v1/notifications
const getUserNotifications = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.id;
    const notifications = await Notification.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']]
    });

    return res.json({
      success: true,
      data: notifications
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getUserNotifications
};
