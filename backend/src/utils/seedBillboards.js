const { User, Billboard } = require('../models');
const { generateQRCodeDataURL } = require('../services/qrCodeService');

const sampleBillboards = [
  {
    billboardCode: 'SMART-YDE-01',
    billboardName: 'Smart TV Display - Central Mall Food Court',
    location: 'Yaounde - Central Mall',
    address: 'Boulevard du 20 Mai, Yaounde, Cameroon',
    latitude: 3.8666,
    longitude: 11.5167,
    description: 'High-definition 4K Smart TV advertising display situated directly in the busy Central Mall food court and main concourse.',
    billboardType: 'SMART_TV',
    screenSize: '65 inch 4K UHD',
    resolution: '3840x2160',
    width: '144cm',
    height: '83cm',
    pricePerHour: 15000.0,
    operatingHours: '08:00 - 22:00',
    images: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800',
    videoDemo: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    technicalSpecs: 'Brightness: 500 nits, Refresh Rate: 120Hz, Smart TV OS: Android/Tizen, HDR10+ Support',
    additionalInfo: 'High foot traffic area with average dwell time of 25 minutes.',
    approvalStatus: 'APPROVED',
    displayStatus: 'ACTIVE',
    availabilityStatus: 'AVAILABLE'
  },
  {
    billboardCode: 'SMART-DLA-01',
    billboardName: 'Smart TV Screen - Akwa Commercial Boulevard',
    location: 'Douala - Akwa Boulevard',
    address: 'Avenue Ahmadou Ahidjo, Akwa, Douala, Cameroon',
    latitude: 4.0511,
    longitude: 9.7679,
    description: 'Prime commercial outdoor-facing Smart TV display located in the heart of Akwa financial and shopping district.',
    billboardType: 'SMART_TV',
    screenSize: '55 inch OLED 4K',
    resolution: '3840x2160',
    width: '123cm',
    height: '71cm',
    pricePerHour: 18000.0,
    operatingHours: '06:00 - 23:00',
    images: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=800',
    videoDemo: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    technicalSpecs: 'Ultra-bright OLED 1000 nits, Continuous 24/7 commercial duty, Audio output enabled',
    additionalInfo: 'Captures daily commuters, corporate workers, and shoppers.',
    approvalStatus: 'APPROVED',
    displayStatus: 'ACTIVE',
    availabilityStatus: 'AVAILABLE'
  },
  {
    billboardCode: 'SMART-YDE-02',
    billboardName: 'Smart TV Billboard - Bastos Embassy Junction',
    location: 'Yaounde - Bastos',
    address: 'Rond-point Bastos, Yaounde, Cameroon',
    latitude: 3.8920,
    longitude: 11.5120,
    description: 'Exclusive digital billboard targeted at high-net-worth individuals, diplomats, and international visitors.',
    billboardType: 'SMART_TV',
    screenSize: '75 inch Crystal UHD',
    resolution: '3840x2160',
    width: '168cm',
    height: '96cm',
    pricePerHour: 22000.0,
    operatingHours: '07:00 - 23:00',
    images: 'https://images.unsplash.com/photo-1508873696983-2df5293cb32f?q=80&w=800',
    videoDemo: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    technicalSpecs: 'Crystal UHD panel, Anti-glare coating, Automated ambient light sensor',
    additionalInfo: 'Premium demographic exposure for luxury brands and corporate campaigns.',
    approvalStatus: 'APPROVED',
    displayStatus: 'ACTIVE',
    availabilityStatus: 'AVAILABLE'
  },
  {
    billboardCode: 'SMART-DLA-02',
    billboardName: 'Digital Screen - Bonanjo Banking Plaza',
    location: 'Douala - Bonanjo',
    address: 'Rue Joss, Bonanjo, Douala, Cameroon',
    latitude: 4.0435,
    longitude: 9.6890,
    description: 'High visibility Smart TV digital signage placed at entrance of the main corporate banking plaza in Bonanjo.',
    billboardType: 'SMART_TV',
    screenSize: '65 inch High-Brightness QLED',
    resolution: '1920x1080',
    width: '144cm',
    height: '83cm',
    pricePerHour: 20000.0,
    operatingHours: '07:00 - 21:00',
    images: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=800',
    videoDemo: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    technicalSpecs: 'Commercial Grade QLED, 700 nits, Quad-Core Media Processor',
    additionalInfo: 'Targets banking professionals, business executives, and legal firms.',
    approvalStatus: 'APPROVED',
    displayStatus: 'ACTIVE',
    availabilityStatus: 'AVAILABLE'
  },
  {
    billboardCode: 'SMART-BUE-01',
    billboardName: 'Smart TV Display - Molyko Tech Hub',
    location: 'Buea - Molyko Hub',
    address: 'Molyko Main Road, Buea, Cameroon',
    latitude: 4.1550,
    longitude: 9.2430,
    description: 'Dynamic digital billboard serving the Silicon Mountain tech ecosystem, university students, and local businesses.',
    billboardType: 'SMART_TV',
    screenSize: '55 inch 4K Display',
    resolution: '1920x1080',
    width: '123cm',
    height: '71cm',
    pricePerHour: 12000.0,
    operatingHours: '08:00 - 22:00',
    images: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=800',
    videoDemo: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    technicalSpecs: 'Full HD IPS panel, Wide viewing angle (178°), IoT sensor integration',
    additionalInfo: 'Youthful and tech-savvy audience demographic.',
    approvalStatus: 'APPROVED',
    displayStatus: 'ACTIVE',
    availabilityStatus: 'AVAILABLE'
  },
  {
    billboardCode: 'SMART-BMD-01',
    billboardName: 'Digital Kiosk Screen - Commercial Avenue',
    location: 'Bamenda - Commercial Avenue',
    address: 'Commercial Avenue, Bamenda, Cameroon',
    latitude: 5.9590,
    longitude: 10.1460,
    description: 'High visibility Smart TV digital kiosk located along the central market street in Bamenda.',
    billboardType: 'SMART_TV',
    screenSize: '50 inch Smart Display',
    resolution: '1920x1080',
    width: '112cm',
    height: '65cm',
    pricePerHour: 10000.0,
    operatingHours: '08:00 - 20:00',
    images: 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?q=80&w=800',
    videoDemo: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    technicalSpecs: 'Commercial IPS, VESA mount, Energy efficient standby',
    additionalInfo: 'Reaches thousands of retail shoppers and market visitors daily.',
    approvalStatus: 'APPROVED',
    displayStatus: 'ACTIVE',
    availabilityStatus: 'AVAILABLE'
  }
];

const seedBillboards = async (forceRecreate = false) => {
  if (process.env.NODE_ENV === 'test') return;

  try {
    console.log('📺 Checking / Seeding digital billboards...');

    // Find default owner
    let owner = await User.findOne({ where: { email: 'owner@smartads.cm' } });
    if (!owner) {
      owner = await User.findOne({ where: { role: 'BILLBOARD_OWNER' } });
    }
    if (!owner) {
      owner = await User.findOne({ where: { role: 'ADMIN' } });
    }

    const ownerId = owner ? owner.userId : 1;

    for (const bData of sampleBillboards) {
      let existing = await Billboard.findOne({ where: { billboardCode: bData.billboardCode } });

      // Generate QR Code data for billboard
      let qrCode = null;
      try {
        qrCode = await generateQRCodeDataURL({
          billboardCode: bData.billboardCode,
          billboardName: bData.billboardName,
          location: bData.location,
          pricePerHour: bData.pricePerHour
        });
      } catch (_) {}

      const recordData = {
        ...bData,
        ownerId: ownerId,
        createdBy: ownerId,
        qrCode: qrCode || bData.billboardCode
      };

      if (!existing) {
        await Billboard.create(recordData);
        console.log(`✅ Seeded billboard: [${bData.billboardCode}] ${bData.billboardName}`);
      } else if (forceRecreate) {
        await existing.update(recordData);
        console.log(`🔄 Updated billboard: [${bData.billboardCode}] ${bData.billboardName}`);
      }
    }

    const totalCount = await Billboard.count();
    console.log(`✅ Digital billboards ready in database (Total: ${totalCount} billboards).`);
  } catch (err) {
    console.warn(`⚠️ Notice during billboard seeding: ${err.message}`);
  }
};

if (require.main === module) {
  const { sequelize } = require('../models');
  (async () => {
    await sequelize.authenticate();
    await sequelize.sync();
    await seedBillboards(true);
    process.exit(0);
  })().catch(err => {
    console.error('Seeding failed:', err);
    process.exit(1);
  });
}

module.exports = { seedBillboards, sampleBillboards };
