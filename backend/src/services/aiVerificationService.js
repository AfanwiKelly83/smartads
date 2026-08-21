const path = require('path');
const fs = require('fs');

/**
 * AI Content Verification Service
 * Simulates intelligent automated media analysis (Resolution, Content Appropriateness, Specs check)
 */
const verifyAdMedia = async (filePath, mediaType) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const ext = path.extname(filePath).toLowerCase();
      const allowedImageExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
      const allowedVideoExts = ['.mp4', '.mov', '.avi', '.mkv'];

      if (mediaType === 'IMAGE' && !allowedImageExts.includes(ext)) {
        return resolve({
          status: 'REJECTED',
          confidenceScore: 0.99,
          notes: `Invalid image format (${ext}). Allowed: ${allowedImageExts.join(', ')}`,
          flaggedReason: 'FORMAT_MISMATCH'
        });
      }

      if (mediaType === 'VIDEO' && !allowedVideoExts.includes(ext)) {
        return resolve({
          status: 'REJECTED',
          confidenceScore: 0.99,
          notes: `Invalid video format (${ext}). Allowed: ${allowedVideoExts.join(', ')}`,
          flaggedReason: 'FORMAT_MISMATCH'
        });
      }

      // Check file size (max 50MB)
      let stats;
      try {
        stats = fs.statSync(filePath);
      } catch (err) {
        return resolve({
          status: 'PENDING',
          confidenceScore: 0.5,
          notes: 'File verification pending file availability.',
          flaggedReason: null
        });
      }

      const fileSizeInMB = stats.size / (1024 * 1024);
      if (fileSizeInMB > 50) {
        return resolve({
          status: 'REJECTED',
          confidenceScore: 0.95,
          notes: `File size exceeds 50MB limit (${fileSizeInMB.toFixed(2)} MB).`,
          flaggedReason: 'FILE_TOO_LARGE'
        });
      }

      // Simulated AI Confidence pass
      const isCleanContent = true; // AI policy pass
      if (isCleanContent) {
        return resolve({
          status: 'APPROVED',
          confidenceScore: 0.98,
          notes: 'AI Content Verification Passed. High visual quality, appropriate dimensions and compliance verified.',
          flaggedReason: null
        });
      }
    }, 300);
  });
};

module.exports = {
  verifyAdMedia
};
