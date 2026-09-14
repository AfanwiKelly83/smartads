const { User } = require('../models');
const { Op } = require('sequelize');

/**
 * Helper to sanitize user object (never returns password / hash)
 */
const sanitizeUser = (user) => ({
  userId: user.userId,
  fullName: user.fullName,
  email: user.email,
  phoneNumber: user.phoneNumber,
  role: user.role,
  accountStatus: user.accountStatus,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt
});

/**
 * GET /api/v1/users/profile
 * Get authenticated user profile
 */
const getProfile = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User account not found.'
      });
    }

    return res.status(200).json({
      success: true,
      data: sanitizeUser(user)
    });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/v1/users/profile
 * Update authenticated user profile (only fullName, email, phoneNumber allowed)
 */
const updateProfile = async (req, res, next) => {
  try {
    const { fullName, email, phoneNumber } = req.body;

    const user = await User.findByPk(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User account not found.'
      });
    }

    // 1. Email validation & duplicate check if email is provided
    if (email !== undefined) {
      const emailTrimmed = String(email).trim();
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

      if (!emailTrimmed || !emailRegex.test(emailTrimmed)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid email format.'
        });
      }

      // Check if email belongs to another user
      const existingUser = await User.findOne({
        where: {
          email: emailTrimmed,
          userId: { [Op.ne]: user.userId }
        }
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'Email address is already registered.'
        });
      }

      user.email = emailTrimmed;
    }

    // 2. FullName validation
    if (fullName !== undefined) {
      const fullNameTrimmed = String(fullName).trim();
      if (!fullNameTrimmed) {
        return res.status(400).json({
          success: false,
          message: 'fullName cannot be empty.'
        });
      }
      user.fullName = fullNameTrimmed;
    }

    // 3. PhoneNumber update
    if (phoneNumber !== undefined) {
      user.phoneNumber = phoneNumber === null ? null : String(phoneNumber).trim();
    }

    // Note: userId, role, password, createdAt, updatedAt are explicitly protected
    // and cannot be modified through this endpoint.

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      data: sanitizeUser(user)
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/v1/users
 * Admin-only user list. Password hashes are never exposed.
 */
const getAllUsers = async (req, res, next) => {
  try {
    const users = await User.findAll({
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']]
    });
    return res.json({ success: true, data: users.map(sanitizeUser) });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/v1/users/:userId
 * Admin-only update of another user's account details and status.
 */
const updateUserByAdmin = async (req, res, next) => {
  try {
    const userId = Number(req.params.userId);
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User account not found.' });
    }
    if (user.userId === req.user.userId && req.body.accountStatus !== 'ACTIVE') {
      return res.status(400).json({ success: false, message: 'You cannot suspend or block your own admin account.' });
    }

    const { fullName, email, phoneNumber, role, accountStatus } = req.body;
    if (fullName !== undefined) {
      const nextName = String(fullName).trim();
      if (!nextName) return res.status(400).json({ success: false, message: 'fullName cannot be empty.' });
      user.fullName = nextName;
    }
    if (email !== undefined) {
      const nextEmail = String(email).trim();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(nextEmail)) {
        return res.status(400).json({ success: false, message: 'Invalid email format.' });
      }
      const duplicate = await User.findOne({ where: { email: nextEmail, userId: { [Op.ne]: user.userId } } });
      if (duplicate) return res.status(409).json({ success: false, message: 'Email address is already registered.' });
      user.email = nextEmail;
    }
    if (phoneNumber !== undefined) user.phoneNumber = phoneNumber === null ? null : String(phoneNumber).trim();
    if (role !== undefined) {
      const nextRole = String(role).toUpperCase();
      if (!['ADMIN', 'ADVERTISER', 'BILLBOARD_OWNER', 'USER'].includes(nextRole)) {
        return res.status(400).json({ success: false, message: 'Unsupported user role.' });
      }
      user.role = nextRole;
    }
    if (accountStatus !== undefined) {
      const nextStatus = String(accountStatus).toUpperCase();
      if (!['ACTIVE', 'SUSPENDED', 'BLOCKED'].includes(nextStatus)) {
        return res.status(400).json({ success: false, message: 'Unsupported account status.' });
      }
      user.accountStatus = nextStatus;
    }

    await user.save();
    return res.json({ success: true, message: 'User account updated successfully.', data: sanitizeUser(user) });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getProfile,
  updateProfile,
  getAllUsers,
  updateUserByAdmin
};
