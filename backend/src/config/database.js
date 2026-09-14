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
  } catch (err) {
    // The table is created by sequelize.sync() during first startup.
    console.warn(`⚠️ Notice during advertisement schema check: ${err.message}`);
  }
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

module.exports = sequelize;
