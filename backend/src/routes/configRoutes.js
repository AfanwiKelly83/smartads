const express = require('express');
const router = express.Router();

// GET /api/v1/config/maps-key
// Returns the Google Maps API key loaded from backend environment variables (.env)
router.get('/maps-key', (req, res) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY || '';
  return res.json({
    success: true,
    data: {
      apiKey: apiKey
    }
  });
});

module.exports = router;
