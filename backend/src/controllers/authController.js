const jwt = require('jsonwebtoken');
const { User } = require('../models');

const generateToken = (user) => {
  const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_smart_billboard_2026';
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d';

  return jwt.sign(
    { userId: user.userId, email: user.email, role: user.role },
    secret,
    { expiresIn }
  );
};

// POST /api/v1/auth/register
const register = async (req, res, next) => {
  try {
    const { fullName, email, password, role, phoneNumber } = req.body;

    // 1. Validation
    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'fullName, email, and password are required.'
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format.'
      });
    }

    // 2. Duplicate Email Check (HTTP 409)
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Email address is already registered.'
      });
    }

    // 3. Only explicitly requested supported roles are accepted.
    const requestedRole = String(role || 'USER').toUpperCase();
    const userRole = ['ADMIN', 'ADVERTISER', 'BILLBOARD_OWNER', 'USER'].includes(requestedRole)
      ? requestedRole
      : 'USER';

    const user = await User.create({
      fullName,
      email,
      password,
      role: userRole,
      phoneNumber
    });


    const token = generateToken(user);

    // 4. Return User Without Password
    return res.status(201).json({
      success: true,
      message: 'User registered successfully.',
      data: {
        token,
        user: {
          userId: user.userId,
          fullName: user.fullName,
          email: user.email,
          phoneNumber: user.phoneNumber,
          role: user.role
        }
      }
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // 1. Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.'
      });
    }

    // 2. Find User
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    // 3. Compare Password (bcrypt)
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    if (user.accountStatus === 'BLOCKED') {
      return res.status(403).json({
        success: false,
        message: 'This account is blocked.'
      });
    }
    if (user.accountStatus === 'SUSPENDED') {
      return res.status(403).json({
        success: false,
        message: 'This account is suspended.'
      });
    }

    // 4. Generate JWT Token
    const token = generateToken(user);

    return res.json({
      success: true,
      message: 'Login successful.',
      data: {
        token,
        user: {
          userId: user.userId,
          fullName: user.fullName,
          email: user.email,
          phoneNumber: user.phoneNumber,
          role: user.role
        }
      }
    });
  } catch (err) {
    next(err);
  }
};

const sanitizeUser = (user) => ({
  userId: user.userId,
  fullName: user.fullName,
  email: user.email,
  phoneNumber: user.phoneNumber,
  role: user.role,
  createdAt: user.createdAt
});

// GET /api/v1/auth/me
const getProfile = async (req, res, next) => {
  try {
    return res.json({
      success: true,
      data: sanitizeUser(req.user)
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/auth/me
const updateProfile = async (req, res, next) => {
  try {
    const { fullName, phoneNumber } = req.body;

    if (!fullName || !String(fullName).trim()) {
      return res.status(400).json({
        success: false,
        message: 'fullName is required.'
      });
    }

    const nextFullName = String(fullName).trim();
    const nextPhoneNumber = phoneNumber === undefined || phoneNumber === null
      ? req.user.phoneNumber
      : String(phoneNumber).trim() || null;

    req.user.fullName = nextFullName;
    req.user.phoneNumber = nextPhoneNumber;
    await req.user.save();

    return res.json({
      success: true,
      message: 'Profile updated successfully.',
      data: sanitizeUser(req.user)
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/auth/change-password
const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'currentPassword and newPassword are required.'
      });
    }

    if (String(newPassword).length < 8) {
      return res.status(400).json({
        success: false,
        message: 'newPassword must be at least 8 characters long.'
      });
    }

    const isCurrentPasswordValid = await req.user.comparePassword(currentPassword);
    if (!isCurrentPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect.'
      });
    }

    req.user.password = String(newPassword);
    await req.user.save();

    return res.json({
      success: true,
      message: 'Password changed successfully.'
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword
};
