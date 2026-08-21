const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const resetDatabase = async () => {
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASS || '';
  const database = process.env.DB_NAME || 'smart_billboard_db';

  console.log(`🔌 Connecting to MySQL server at ${host}:${port} as user '${user}'...`);

  const connection = await mysql.createConnection({ host, port, user, password });

  console.log(`🗑️ Dropping development database '${database}' if exists...`);
  await connection.query(`DROP DATABASE IF EXISTS \`${database}\`;`);

  console.log(`✨ Recreating clean development database '${database}'...`);
  await connection.query(`CREATE DATABASE \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`);

  await connection.end();
  console.log(`✅ Database '${database}' reset successfully.`);

  // Load models (ensuring associations are loaded before sync)
  const { sequelize } = require('../models');

  console.log('🔄 Synchronizing tables from corrected Sequelize models...');
  await sequelize.sync();

  console.log('✅ All tables and foreign keys created successfully in correct dependency order!');
};

if (require.main === module) {
  resetDatabase()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Reset failed:', err);
      process.exit(1);
    });
}

module.exports = { resetDatabase };
