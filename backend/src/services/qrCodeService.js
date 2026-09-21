const QRCode = require('qrcode');
const path = require('path');
const fs = require('fs');

/**
 * Service to automatically generate QR Code for a billboard
 */
const generateBillboardQRCode = async (billboard) => {
  const qrDir = path.join(__dirname, '../../uploads/qrcodes');
  if (!fs.existsSync(qrDir)) {
    fs.mkdirSync(qrDir, { recursive: true });
  }

  const qrFileName = `qr_billboard_${billboard.billboardId}.png`;
  const qrFilePath = path.join(qrDir, qrFileName);

  const code = billboard.billboardCode || `BILL-${String(billboard.billboardId).padStart(3, '0')}`;
  const baseUrl = process.env.BILLBOARD_PUBLIC_URL || 'https://smartads.cm/billboard';
  const qrTargetUrl = `${baseUrl}/${code}`;

  const payload = JSON.stringify({
    billboardId: billboard.billboardId,
    billboardCode: code,
    billboardName: billboard.billboardName,
    location: billboard.location,
    url: qrTargetUrl
  });

  await QRCode.toFile(qrFilePath, payload, {
    color: {
      dark: '#0F172A',
      light: '#FFFFFF'
    },
    width: 350
  });

  return `/uploads/qrcodes/${qrFileName}`;
};

module.exports = {
  generateBillboardQRCode
};
