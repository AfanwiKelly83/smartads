const { getActivePlaylistForBillboard } = require('../services/schedulerService');

// GET /api/scheduler/playlist/:billboardId
const getBillboardPlaylist = async (req, res, next) => {
  try {
    const { billboardId } = req.params;

    const playlistData = await getActivePlaylistForBillboard(billboardId);

    return res.json({
      success: true,
      data: playlistData
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getBillboardPlaylist
};
