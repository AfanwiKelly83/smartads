const express = require('express');
const cors = require('cors');
const path = require('path');
const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static assets for uploads and QR codes
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Health Check Endpoint
app.get('/api/v1/health', (req, res) => {
  res.json({
    success: true,
    system: 'SMARTADS Digital Billboard Advertising System API',
    version: '1.0.0',
    status: 'ONLINE',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.redirect('/api/v1/health');
});

// API v1 Routes
app.use('/api/v1', routes);

// Error Handler
app.use(errorHandler);

module.exports = app;
