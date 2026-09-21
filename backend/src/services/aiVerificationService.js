const path = require('path');
const fs = require('fs');
const os = require('os');
const crypto = require('crypto');
const { execFile } = require('child_process');
const { promisify } = require('util');
const ffmpegStatic = require('ffmpeg-static');

const execFileAsync = promisify(execFile);
const allowedImageExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
const allowedVideoExts = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];

const pending = (notes, flaggedReason = 'VERIFICATION_UNAVAILABLE') => ({
  status: 'PENDING',
  confidenceScore: null,
  notes,
  flaggedReason
});

const extractVideoFrames = async (filePath) => {
  const directory = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'smartads-frames-'));
  const outputPattern = path.join(directory, 'frame-%02d.jpg');
  const ffmpeg = process.env.FFMPEG_PATH || ffmpegStatic || 'ffmpeg';

  try {
    await execFileAsync(ffmpeg, [
      '-y', '-i', filePath, '-vf', 'fps=1/3,scale=768:-1', '-frames:v', '3', outputPattern
    ]);
    const files = (await fs.promises.readdir(directory))
      .filter((file) => file.endsWith('.jpg'))
      .sort()
      .map((file) => path.join(directory, file));
    return { files, directory };
  } catch (error) {
    await fs.promises.rm(directory, { recursive: true, force: true });
    throw error;
  }
};

const toImageUrl = async (filePath) => {
  if (/^https?:\/\//i.test(filePath)) return filePath;
  const buffer = await fs.promises.readFile(filePath);
  const extension = path.extname(filePath).toLowerCase();
  const mime = extension === '.png' ? 'image/png' : extension === '.webp' ? 'image/webp' : 'image/jpeg';
  return `data:${mime};base64,${buffer.toString('base64')}`;
};

const parseModelResult = (content) => {
  const json = content.match(/\{[\s\S]*\}/)?.[0];
  if (!json) throw new Error('OpenRouter returned non-JSON verification output.');
  const result = JSON.parse(json);
  const status = String(result.status || '').toUpperCase();
  if (!['APPROVED', 'REJECTED'].includes(status)) throw new Error('OpenRouter returned an invalid verification status.');
  return {
    status,
    confidenceScore: Number.isFinite(Number(result.confidenceScore)) ? Number(result.confidenceScore) : null,
    notes: String(result.notes || 'No verification notes were returned.'),
    flaggedReason: result.flaggedReason ? String(result.flaggedReason) : null
  };
};

const verifyWithOpenRouter = async (imageUrls, mediaType) => {
  if (!process.env.OPENROUTER_API_KEY) {
    return pending('AI verification is not configured. Set OPENROUTER_API_KEY on the backend.');
  }

  const response = await fetch(process.env.OPENROUTER_URL || 'https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'HTTP-Referer': process.env.OPENROUTER_SITE_URL || 'http://localhost:3000',
      'X-Title': process.env.OPENROUTER_SITE_NAME || 'SmartAds',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: process.env.OPENROUTER_MODEL || 'openai/gpt-4o',
      temperature: 0,
      max_tokens: 300,
      messages: [{
        role: 'user',
        content: [
          { type: 'text', text: `Review this ${mediaType.toLowerCase()} advertisement for public digital billboard display. Reject sexual content, graphic violence, hate, illegal activity, dangerous instructions, scams, or clearly unreadable/low-quality media. Return JSON only: {"status":"APPROVED"|"REJECTED","confidenceScore":0-1,"notes":"short explanation","flaggedReason":"SAFETY|QUALITY|FORMAT|null"}.` },
          ...imageUrls.map((url) => ({ type: 'image_url', image_url: { url } }))
        ]
      }]
    })
  });

  if (!response.ok) throw new Error(`OpenRouter verification failed with HTTP ${response.status}.`);
  const payload = await response.json();
  return parseModelResult(payload.choices?.[0]?.message?.content || '');
};

const { verifyAdvertisementContent } = require('./geminiService');

const verifyAdMedia = async (filePath, mediaType, title = '') => {
  return await verifyAdvertisementContent(filePath, mediaType, title);
};

module.exports = {
  verifyAdMedia,
  verifyAdvertisementContent
};
