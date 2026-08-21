const express = require('express');
const router = express.Router();
const { getBillboardPlaylist } = require('../controllers/schedulerController');

router.get('/playlist/:billboardId', getBillboardPlaylist);

module.exports = router;
