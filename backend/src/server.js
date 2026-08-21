const app = require('./app');
const { sequelize } = require('./models');
const { checkExpiredCampaigns } = require('./services/schedulerService');
const dotenv = require('dotenv');

dotenv.config();

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    // Auto-create database if not exists
    if (typeof sequelize.ensureDatabaseExists === 'function') {
      await sequelize.ensureDatabaseExists();
    }

    // Authenticate database connection
    await sequelize.authenticate();
    console.log('Database connection successful');

    // Synchronize Sequelize Models with Database
    await sequelize.sync();
    console.log('Database schema synchronized successfully');

    // Start background cron jobs (running every 60 seconds)
    setInterval(async () => {
      await checkExpiredCampaigns();
    }, 60000);

    const server = app.listen(PORT, () => {
      console.log(`SMARTADS backend running on port ${PORT}`);
      console.log(`📡 Health Check URL: http://localhost:${PORT}/api/v1/health`);
    });

    return server;
  } catch (err) {
    console.error('❌ Unable to connect to the database:', err.message);
    if (err.parent) {
      console.error('Exact SQL Error:', err.parent.sqlMessage || err.parent.message);
      console.error('SQL Code:', err.parent.code);
    }
    process.exit(1);
  }
};

if (process.env.NODE_ENV !== 'test') {
  startServer();
}

module.exports = { startServer };
