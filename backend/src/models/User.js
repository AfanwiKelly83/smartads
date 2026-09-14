const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  userId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  fullName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  phoneNumber: {
    type: DataTypes.STRING,
    allowNull: true
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  },
  role: {
    type: DataTypes.ENUM('ADMIN', 'ADVERTISER', 'BILLBOARD_OWNER', 'USER'),
    defaultValue: 'USER',
    allowNull: false
  },
  accountStatus: {
    type: DataTypes.ENUM('ACTIVE', 'SUSPENDED', 'BLOCKED'),
    defaultValue: 'ACTIVE',
    allowNull: false
  }
}, {
  timestamps: true,
  tableName: 'Users',
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        const rounds = process.env.NODE_ENV === 'test' ? 1 : 10;
        const salt = await bcrypt.genSalt(rounds);
        user.password = await bcrypt.hash(user.password, salt);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        const rounds = process.env.NODE_ENV === 'test' ? 1 : 10;
        const salt = await bcrypt.genSalt(rounds);
        user.password = await bcrypt.hash(user.password, salt);
      }
    }
  }
});

User.prototype.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = User;
