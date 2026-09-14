const jwt = require('jsonwebtoken');
const { User } = require('../models');

/**
 * Authentication Middleware
 * Validates Bearer JWT Token from Authorization header
 */
const requireAuth = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Authentication token required.'
    });
  }

  try {
    const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_smart_billboard_2026';
    const decoded = jwt.verify(token, secret);
    const user = await User.findByPk(decoded.userId || decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User account not found or invalid.'
      });
    }

    if (user.accountStatus === 'BLOCKED') {
      return res.status(403).json({ success: false, message: 'This account is blocked.' });
    }
    if (user.accountStatus === 'SUSPENDED') {
      return res.status(403).json({ success: false, message: 'This account is suspended.' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired authentication token.'
    });
  }
};

/**
 * Role Authorization Middleware
 * Enforces role access control (ADMIN, ADVERTISER, USER)
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden. Action requires role: [${roles.join(', ')}]`
      });
    }
    next();
  };
};

module.exports = {
  requireAuth,
  requireRole,
  authenticateToken: requireAuth,
  authorize: requireRole,
  authenticate: requireAuth
};
