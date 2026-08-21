const { calculateSystemStatistics } = require('../services/analyticsService');

// GET /api/v1/analytics
const getSystemStatistics = async (req, res, next) => {
  try {
    const stats = await calculateSystemStatistics();
    return res.json({
      success: true,
      data: stats
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getSystemStatistics
};
