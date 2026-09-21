const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Billboard = sequelize.define('Billboard', {
  billboardId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  billboardCode: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true
  },
  billboardName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  ownerId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Users',
      key: 'userId'
    }
  },
  location: {
    type: DataTypes.STRING,
    allowNull: false
  },
  address: {
    type: DataTypes.STRING,
    allowNull: true
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  billboardType: {
    type: DataTypes.STRING,
    defaultValue: 'SMART_TV'
  },
  width: {
    type: DataTypes.STRING,
    allowNull: true
  },
  height: {
    type: DataTypes.STRING,
    allowNull: true
  },
  resolution: {
    type: DataTypes.STRING,
    defaultValue: '1920x1080'
  },
  pricePerHour: {
    type: DataTypes.FLOAT,
    allowNull: false,
    defaultValue: 15000.0
  },
  approvalStatus: {
    type: DataTypes.ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'SUSPENDED', 'UNPUBLISHED'),
    defaultValue: 'PENDING_APPROVAL'
  },
  displayStatus: {
    type: DataTypes.ENUM('ACTIVE', 'INACTIVE', 'MAINTENANCE'),
    defaultValue: 'ACTIVE'
  },
  availabilityStatus: {
    type: DataTypes.ENUM('AVAILABLE', 'BOOKED', 'UNAVAILABLE'),
    defaultValue: 'AVAILABLE'
  },
  operatingHours: {
    type: DataTypes.STRING,
    defaultValue: '06:00 - 22:00'
  },
  images: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  videoDemo: {
    type: DataTypes.STRING,
    allowNull: true
  },
  technicalSpecs: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  additionalInfo: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  qrCode: {
    type: DataTypes.STRING,
    allowNull: true
  },
  createdBy: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'userId'
    }
  },
  latitude: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  longitude: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  screenSize: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true,
  tableName: 'Billboards',
  hooks: {
    beforeCreate: (billboard) => {
      if (!billboard.ownerId && billboard.createdBy) {
        billboard.ownerId = billboard.createdBy;
      }
      if (!billboard.createdBy && billboard.ownerId) {
        billboard.createdBy = billboard.ownerId;
      }
    }
  }
});

module.exports = Billboard;
