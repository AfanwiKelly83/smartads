const { Sequelize } = require('sequelize');
const dotenv = require('dotenv');
const mysql = require('mysql2/promise');

const currentEnv = process.env.NODE_ENV;
dotenv.config();
if (currentEnv) {
  process.env.NODE_ENV = currentEnv;
}

const ensureDatabaseExists = async () => {
  if (process.env.NODE_ENV === 'test') return;
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASS || '';
  const database = process.env.DB_NAME || 'smart_billboard_db';

  try {
    const connection = await mysql.createConnection({ host, port, user, password });
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${database}\`;`);
    await connection.end();
    console.log(`✅ Ensured MySQL database '${database}' exists.`);
  } catch (err) {
    console.warn(`⚠️ Notice during database existence check: ${err.message}`);
  }
};

const ensureUserRoleValues = async () => {
  if (process.env.NODE_ENV === 'test') return;

  try {
    await sequelize.query(
      "ALTER TABLE `Users` MODIFY `role` ENUM('ADMIN', 'ADVERTISER', 'BILLBOARD_OWNER', 'USER') NOT NULL DEFAULT 'USER';"
    );

    const [columns] = await sequelize.query('SHOW COLUMNS FROM `Users` LIKE \'accountStatus\';');
    if (columns.length === 0) {
      await sequelize.query(
        "ALTER TABLE `Users` ADD `accountStatus` ENUM('ACTIVE', 'SUSPENDED', 'BLOCKED') NOT NULL DEFAULT 'ACTIVE';"
      );
      console.log('✅ Added missing account status column to Users.');
    }

    console.log('✅ Ensured supported user roles are available.');
  } catch (err) {
    // A fresh database has no Users table until sequelize.sync() runs.
    console.warn(`⚠️ Notice during user role schema check: ${err.message}`);
  }
};

const ensureAdvertisementColumns = async () => {
  if (process.env.NODE_ENV === 'test') return;

  const columns = [
    ['verificationNotes', 'TEXT NULL'],
    ['adminNotes', 'TEXT NULL'],
    ['correctionReason', 'TEXT NULL'],
    ['aiConfidenceScore', 'FLOAT NULL'],
    ['aiFlaggedReason', 'VARCHAR(255) NULL'],
    ['playStartTime', 'VARCHAR(255) NULL'],
    ['playEndTime', 'VARCHAR(255) NULL']
  ];

  try {
    const [existingColumns] = await sequelize.query(
      'SHOW COLUMNS FROM `Advertisements`;'
    );
    const existingNames = new Set(
      existingColumns.map((column) => column.Field.toLowerCase())
    );

    for (const [name, definition] of columns) {
      if (!existingNames.has(name.toLowerCase())) {
        await sequelize.query(
          `ALTER TABLE \`Advertisements\` ADD COLUMN \`${name}\` ${definition};`
        );
        console.log(`✅ Added missing Advertisements.${name} column.`);
      }
    }

    try {
      await sequelize.query(
        "ALTER TABLE `Advertisements` MODIFY COLUMN `approvalStatus` ENUM('PENDING_AI_REVIEW', 'AI_APPROVED', 'AI_REJECTED', 'AI_FLAGGED', 'MANUAL_REVIEW', 'APPROVED', 'REJECTED', 'PENDING') NOT NULL DEFAULT 'PENDING_AI_REVIEW';"
      );
    } catch (_) {}
  } catch (err) {
    // The table is created by sequelize.sync() during first startup.
    console.warn(`⚠️ Notice during advertisement schema check: ${err.message}`);
  }
};

const ensureBillboardColumns = async () => {
  if (process.env.NODE_ENV === 'test') return;

  const columns = [
    ['billboardCode', 'VARCHAR(255) NULL'],
    ['ownerId', 'INT NULL'],
    ['address', 'VARCHAR(255) NULL'],
    ['description', 'TEXT NULL'],
    ['billboardType', "VARCHAR(255) DEFAULT 'SMART_TV'"],
    ['width', 'VARCHAR(255) NULL'],
    ['height', 'VARCHAR(255) NULL'],
    ['resolution', "VARCHAR(255) DEFAULT '1920x1080'"],
    ['pricePerHour', 'FLOAT NOT NULL DEFAULT 15000.0'],
    ['maxActiveCampaigns', 'INT NOT NULL DEFAULT 10'],
    ['approvalStatus', "ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'SUSPENDED', 'UNPUBLISHED') DEFAULT 'PENDING_APPROVAL'"],
    ['displayStatus', "ENUM('ACTIVE', 'INACTIVE', 'MAINTENANCE') DEFAULT 'ACTIVE'"],
    ['availabilityStatus', "ENUM('AVAILABLE', 'BOOKED', 'UNAVAILABLE') DEFAULT 'AVAILABLE'"],
    ['operatingHours', "VARCHAR(255) DEFAULT '06:00 - 22:00'"],
    ['images', 'TEXT NULL'],
    ['videoDemo', 'VARCHAR(255) NULL'],
    ['technicalSpecs', 'TEXT NULL'],
    ['additionalInfo', 'TEXT NULL'],
    ['qrCode', 'VARCHAR(255) NULL'],
    ['latitude', 'FLOAT NULL'],
    ['longitude', 'FLOAT NULL'],
    ['screenSize', 'VARCHAR(255) NULL']
  ];

  try {
    const [existingColumns] = await sequelize.query(
      'SHOW COLUMNS FROM `Billboards`;'
    );
    const existingNames = new Set(
      existingColumns.map((column) => column.Field.toLowerCase())
    );

    for (const [name, definition] of columns) {
      if (!existingNames.has(name.toLowerCase())) {
        await sequelize.query(
          `ALTER TABLE \`Billboards\` ADD COLUMN \`${name}\` ${definition};`
        );
        console.log(`✅ Added missing Billboards.${name} column.`);
      }
    }
  } catch (err) {
    console.warn(`⚠️ Notice during billboard schema check: ${err.message}`);
  }
};

const ensureBookingColumns = async () => {
  if (process.env.NODE_ENV === 'test') return;

  const columns = [
    ['startTime', "VARCHAR(255) DEFAULT '00:00'"],
    ['endTime', "VARCHAR(255) DEFAULT '23:59'"],
    ['repeatOption', "VARCHAR(255) DEFAULT 'DAILY'"],
    ['status', "ENUM('PENDING', 'CONFIRMED', 'REJECTED', 'EXPIRED') DEFAULT 'PENDING'"],
    ['totalAmount', 'FLOAT DEFAULT 0.0']
  ];

  try {
    const [existingColumns] = await sequelize.query(
      'SHOW COLUMNS FROM `Bookings`;'
    );
    const existingNames = new Set(
      existingColumns.map((column) => column.Field.toLowerCase())
    );

    for (const [name, definition] of columns) {
      if (!existingNames.has(name.toLowerCase())) {
        await sequelize.query(
          `ALTER TABLE \`Bookings\` ADD COLUMN \`${name}\` ${definition};`
        );
        console.log(`✅ Added missing Bookings.${name} column.`);
      }
    }
  } catch (err) {
    console.warn(`⚠️ Notice during booking schema check: ${err.message}`);
  }
};

const ensureAllSchemaColumns = async () => {
  await ensureUserRoleValues();
  await ensureBillboardColumns();
  await ensureAdvertisementColumns();
  await ensureBookingColumns();
};

let sequelize;

if (process.env.NODE_ENV === 'test') {
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: ':memory:',
    logging: false
  });
} else {
  sequelize = new Sequelize(
    process.env.DB_NAME || 'smart_billboard_db',
    process.env.DB_USER || 'root',
    process.env.DB_PASS || '',
    {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306', 10),
      dialect: 'mysql',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      pool: {
        max: 10,
        min: 0,
        acquire: 30000,
        idle: 10000
      }
    }
  );
}

sequelize.ensureDatabaseExists = ensureDatabaseExists;
sequelize.ensureUserRoleValues = ensureUserRoleValues;
sequelize.ensureAdvertisementColumns = ensureAdvertisementColumns;
sequelize.ensureBillboardColumns = ensureBillboardColumns;
sequelize.ensureBookingColumns = ensureBookingColumns;
sequelize.ensureAllSchemaColumns = ensureAllSchemaColumns;

module.exports = sequelize;
