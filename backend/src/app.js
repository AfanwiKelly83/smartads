const express = require('express');
const cors = require('cors');
const path = require('path');
const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

// CORS — allow Flutter web (localhost any port), Android emulator, and desktop
const allowedOrigins = [
  /^http:\/\/localhost(:\d+)?$/,      // Flutter web & desktop dev
  /^http:\/\/127\.0\.0\.1(:\d+)?$/,  // Loopback alias
  /^http:\/\/10\.0\.2\.2(:\d+)?$/,   // Android emulator → host machine
];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, Postman)
    if (!origin) return callback(null, true);
    const allowed = allowedOrigins.some((pattern) => pattern.test(origin));
    if (allowed) return callback(null, true);
    callback(new Error(`CORS blocked: ${origin}`));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Handle pre-flight OPTIONS for all routes (Express 5 compatible wildcard)
app.options('/{*path}', cors());

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
