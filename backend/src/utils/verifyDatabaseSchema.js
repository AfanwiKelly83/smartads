const mysql = require('mysql2/promise');
const { sequelize } = require('../models');
const dotenv = require('dotenv');

dotenv.config();

const verifySchema = async () => {
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASS || '';
  const database = process.env.DB_NAME || 'smart_billboard_db';

  const connection = await mysql.createConnection({ host, port, user, password, database });

  console.log('🔍 Checking MySQL database tables...');
  const [tablesResult] = await connection.query('SHOW TABLES;');
  const tableNames = tablesResult.map((row) => Object.values(row)[0].toLowerCase());

  const expectedTables = [
    'Users',
    'Billboards',
    'Advertisements',
    'Campaigns',
    'Bookings',
    'Payments',
    'Notifications',
    'CampaignBillboards',
    'IoTDevices',
    'PlaybackLogs'
  ];

  console.log('\n--- 📋 TABLES VERIFICATION ---');
  for (const table of expectedTables) {
    const exists = tableNames.includes(table.toLowerCase());
    console.log(`Table '${table}': ${exists ? '✅ EXISTS' : '❌ MISSING'}`);
  }

  console.log('\n--- 🔑 FOREIGN KEYS VERIFICATION ---');
  const [fkResult] = await connection.query(`
    SELECT 
      TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
    FROM 
      information_schema.KEY_COLUMN_USAGE
    WHERE 
      TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL;
  `, [database]);

  const expectedFKs = [
    { table: 'Billboards', column: 'createdBy', refTable: 'Users', refColumn: 'userId' },
    { table: 'Advertisements', column: 'advertiserId', refTable: 'Users', refColumn: 'userId' },
    { table: 'Campaigns', column: 'advertiserId', refTable: 'Users', refColumn: 'userId' },
    { table: 'Bookings', column: 'advertiserId', refTable: 'Users', refColumn: 'userId' },
    { table: 'Bookings', column: 'billboardId', refTable: 'Billboards', refColumn: 'billboardId' },
    { table: 'Bookings', column: 'campaignId', refTable: 'Campaigns', refColumn: 'campaignId' },
    { table: 'Payments', column: 'bookingId', refTable: 'Bookings', refColumn: 'bookingId' },
    { table: 'Notifications', column: 'userId', refTable: 'Users', refColumn: 'userId' },
    { table: 'IoTDevices', column: 'billboardId', refTable: 'Billboards', refColumn: 'billboardId' },
    { table: 'CampaignBillboards', column: 'campaignId', refTable: 'Campaigns', refColumn: 'campaignId' },
    { table: 'CampaignBillboards', column: 'billboardId', refTable: 'Billboards', refColumn: 'billboardId' }
  ];

  for (const fk of expectedFKs) {
    const found = fkResult.find((row) =>
      row.TABLE_NAME.toLowerCase() === fk.table.toLowerCase() &&
      row.COLUMN_NAME.toLowerCase() === fk.column.toLowerCase() &&
      row.REFERENCED_TABLE_NAME.toLowerCase() === fk.refTable.toLowerCase() &&
      row.REFERENCED_COLUMN_NAME.toLowerCase() === fk.refColumn.toLowerCase()
    );
    console.log(`FK ${fk.table}.${fk.column} -> ${fk.refTable}.${fk.refColumn}: ${found ? '✅ VERIFIED' : '❌ NOT FOUND'}`);
  }

  await connection.end();

  console.log('\n--- 🔗 SEQUELIZE ASSOCIATIONS VERIFICATION ---');
  const models = sequelize.models;

  console.log('User -> Billboard (createdBy):', models.User.associations.createdBillboards ? '✅ OK' : '❌ MISSING');
  console.log('User -> Advertisement (advertiserId):', models.User.associations.advertisements ? '✅ OK' : '❌ MISSING');
  console.log('User -> Campaign (advertiserId):', models.User.associations.campaigns ? '✅ OK' : '❌ MISSING');
  console.log('User -> Booking (advertiserId):', models.User.associations.bookings ? '✅ OK' : '❌ MISSING');
  console.log('Billboard -> Booking (billboardId):', models.Billboard.associations.bookings ? '✅ OK' : '❌ MISSING');
  console.log('Campaign -> Booking (campaignId):', models.Campaign.associations.bookings ? '✅ OK' : '❌ MISSING');
  console.log('Booking -> Payment (bookingId):', models.Booking.associations.payment ? '✅ OK' : '❌ MISSING');
  console.log('Campaign <-> Billboard (CampaignBillboard):', models.Campaign.associations.billboards ? '✅ OK' : '❌ MISSING');
  console.log('User -> Notification (userId):', models.User.associations.notifications ? '✅ OK' : '❌ MISSING');
  console.log('Billboard -> IoTDevice (billboardId):', models.Billboard.associations.iotDevice ? '✅ OK' : '❌ MISSING');
};

if (require.main === module) {
  verifySchema()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Verification failed:', err);
      process.exit(1);
    });
}

module.exports = { verifySchema };
