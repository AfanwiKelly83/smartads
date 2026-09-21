const { verifyAdvertisementContent } = require('./geminiService');

/**
 * Gemini AI Content Verification Service
 */
const verifyAdvertisementWithGemini = async (filePath, mediaType, title = '') => {
  return await verifyAdvertisementContent(filePath, mediaType, title);
};

module.exports = {
  verifyAdvertisementWithGemini
};
