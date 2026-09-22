process.env.NODE_ENV = 'test';
const request = require('supertest');
const app = require('../src/app');
const { sequelize, User, Billboard, Booking, Campaign, Advertisement, IoTDevice, PlaybackLog } = require('../src/models');
const jwt = require('jsonwebtoken');

jest.setTimeout(30000);

describe('SmartAds IoT Hardware, Heartbeats & Tracking Test Suite', () => {
  let adminToken, ownerToken, advertiserToken, userToken;
  let adminUser, ownerUser, advertiserUser, normalUser;
  let ownerBillboard, otherBillboard;
  let testCampaign, testAd;

  beforeAll(async () => {
    await sequelize.sync({ force: true });

    // 1. Create Users
    adminUser = await User.create({
      fullName: 'IoT Super Admin',
      email: 'admin_iot@smartads.cm',
      password: 'Password123!',
      role: 'ADMIN',
      accountStatus: 'ACTIVE'
    });

    ownerUser = await User.create({
      fullName: 'Screen Owner Paul',
      email: 'owner_iot@smartads.cm',
      password: 'Password123!',
      role: 'BILLBOARD_OWNER',
      accountStatus: 'ACTIVE'
    });

    advertiserUser = await User.create({
      fullName: 'Brand Advertiser John',
      email: 'advertiser_iot@smartads.cm',
      password: 'Password123!',
      role: 'ADVERTISER',
      accountStatus: 'ACTIVE'
    });

    normalUser = await User.create({
      fullName: 'Regular Viewer Jane',
      email: 'user_iot@smartads.cm',
      password: 'Password123!',
      role: 'USER',
      accountStatus: 'ACTIVE'
    });

    const jwtSecret = process.env.JWT_SECRET || 'smartads_jwt_secret_dev_key_2026';
    adminToken = jwt.sign({ userId: adminUser.userId, role: 'ADMIN' }, jwtSecret, { expiresIn: '1d' });
    ownerToken = jwt.sign({ userId: ownerUser.userId, role: 'BILLBOARD_OWNER' }, jwtSecret, { expiresIn: '1d' });
    advertiserToken = jwt.sign({ userId: advertiserUser.userId, role: 'ADVERTISER' }, jwtSecret, { expiresIn: '1d' });
    userToken = jwt.sign({ userId: normalUser.userId, role: 'USER' }, jwtSecret, { expiresIn: '1d' });

    // 2. Create Billboards
    ownerBillboard = await Billboard.create({
      billboardName: 'Douala Airport Smart Display',
      location: 'Douala International Airport Terminal 1',
      pricePerHour: 15000,
      maxActiveCampaigns: 5,
      ownerId: ownerUser.userId,
      createdBy: ownerUser.userId,
      displayStatus: 'ACTIVE',
      approvalStatus: 'APPROVED'
    });

    otherBillboard = await Billboard.create({
      billboardName: 'Yaounde Central Mall LED',
      location: 'Yaounde City Center',
      pricePerHour: 20000,
      maxActiveCampaigns: 10,
      ownerId: adminUser.userId,
      createdBy: adminUser.userId,
      displayStatus: 'ACTIVE',
      approvalStatus: 'APPROVED'
    });

    // 3. Create Advertisement & Campaign
    testAd = await Advertisement.create({
      advertiserId: advertiserUser.userId,
      title: 'Mega Promo Campaign Video',
      mediaType: 'VIDEO',
      filePath: '/uploads/megapromo.mp4',
      fileSize: 10 * 1024 * 1024,
      duration: 30,
      approvalStatus: 'APPROVED'
    });

    const today = new Date().toISOString().split('T')[0];
    testCampaign = await Campaign.create({
      advertiserId: advertiserUser.userId,
      campaignType: 'STANDARD',
      startDate: today,
      endDate: today,
      campaignStatus: 'ACTIVE',
      totalCost: 30000
    });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  // ==========================================
  // SECTION 1: IoT Heartbeat & Device Telemetry
  // ==========================================
  describe('1. IoT Device Heartbeat Telemetry API', () => {
    test('POST /api/v1/iot/heartbeat -> should register new IoT device telemetry', async () => {
      const res = await request(app)
        .post('/api/v1/iot/heartbeat')
        .send({
          billboardId: ownerBillboard.billboardId,
          macAddress: 'AA:BB:CC:DD:EE:01',
          firmwareVersion: '2.1.0-ESP32',
          connectionStatus: 'CONNECTED'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('recorded');
      expect(res.body.data.billboardId).toBe(ownerBillboard.billboardId);
      expect(res.body.data.macAddress).toBe('AA:BB:CC:DD:EE:01');
      expect(res.body.data.firmwareVersion).toBe('2.1.0-ESP32');
      expect(res.body.data.connectionStatus).toBe('CONNECTED');
    });

    test('POST /api/v1/iot/heartbeat -> should update existing device heartbeat and lastSeenAt', async () => {
      const res = await request(app)
        .post('/api/v1/iot/heartbeat')
        .send({
          billboardId: ownerBillboard.billboardId,
          macAddress: 'AA:BB:CC:DD:EE:01',
          firmwareVersion: '2.2.0-ESP32',
          connectionStatus: 'CONNECTED'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.firmwareVersion).toBe('2.2.0-ESP32');
      expect(res.body.data.lastSeenAt).toBeDefined();
    });

    test('POST /api/v1/iot/heartbeat -> should reject missing billboardId with 400', async () => {
      const res = await request(app)
        .post('/api/v1/iot/heartbeat')
        .send({
          macAddress: 'AA:BB:CC:DD:EE:99'
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('billboardId is required');
    });

    test('POST /api/v1/iot/heartbeat -> register heartbeat for second billboard', async () => {
      const res = await request(app)
        .post('/api/v1/iot/heartbeat')
        .send({
          billboardId: otherBillboard.billboardId,
          macAddress: 'AA:BB:CC:DD:EE:02',
          firmwareVersion: '1.9.0-RPI',
          connectionStatus: 'WARNING'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.connectionStatus).toBe('WARNING');
    });
  });

  // ==========================================
  // SECTION 2: IoT Device Listing & Role Scoping
  // ==========================================
  describe('2. IoT Device Access Control & Role Scoping', () => {
    test('GET /api/v1/iot/devices -> 401 Unauthorized without token', async () => {
      const res = await request(app).get('/api/v1/iot/devices');
      expect(res.status).toBe(401);
    });

    test('GET /api/v1/iot/devices -> 403 Forbidden for ADVERTISER and USER', async () => {
      const advRes = await request(app)
        .get('/api/v1/iot/devices')
        .set('Authorization', `Bearer ${advertiserToken}`);
      expect(advRes.status).toBe(403);

      const userRes = await request(app)
        .get('/api/v1/iot/devices')
        .set('Authorization', `Bearer ${userToken}`);
      expect(userRes.status).toBe(403);
    });

    test('GET /api/v1/iot/devices -> ADMIN sees all IoT devices across system', async () => {
      const res = await request(app)
        .get('/api/v1/iot/devices')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(2);
    });

    test('GET /api/v1/iot/devices -> BILLBOARD_OWNER sees only their own billboard devices', async () => {
      const res = await request(app)
        .get('/api/v1/iot/devices')
        .set('Authorization', `Bearer ${ownerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].billboardId).toBe(ownerBillboard.billboardId);
    });
  });

  // ==========================================
  // SECTION 3: Playback Tracking & Proof of Play
  // ==========================================
  describe('3. Playback Tracking & Proof of Play API', () => {
    test('POST /api/v1/tracking/log -> should reject with 400 when missing required IDs', async () => {
      const res = await request(app)
        .post('/api/v1/tracking/log')
        .send({
          billboardId: ownerBillboard.billboardId
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    test('POST /api/v1/tracking/log -> record successful playback event', async () => {
      const res = await request(app)
        .post('/api/v1/tracking/log')
        .send({
          billboardId: ownerBillboard.billboardId,
          campaignId: testCampaign.campaignId,
          adId: testAd.advertisementId,
          durationPlayed: 30,
          status: 'SUCCESS'
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('SUCCESS');
      expect(res.body.data.durationPlayed).toBe(30);
    });

    test('POST /api/v1/tracking/log -> record second successful playback event', async () => {
      const res = await request(app)
        .post('/api/v1/tracking/log')
        .send({
          billboardId: ownerBillboard.billboardId,
          campaignId: testCampaign.campaignId,
          adId: testAd.advertisementId,
          durationPlayed: 30,
          status: 'SUCCESS'
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    test('POST /api/v1/tracking/log -> record error / interrupted playback event', async () => {
      const res = await request(app)
        .post('/api/v1/tracking/log')
        .send({
          billboardId: ownerBillboard.billboardId,
          campaignId: testCampaign.campaignId,
          adId: testAd.advertisementId,
          durationPlayed: 5,
          status: 'ERROR'
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('ERROR');
    });
  });

  // ==========================================
  // SECTION 4: Campaign Telemetry Analytics & Delivery
  // ==========================================
  describe('4. Campaign Telemetry & Impression Analytics', () => {
    test('GET /api/v1/tracking/campaign/:id -> calculates accurate plays and airtime', async () => {
      const res = await request(app)
        .get(`/api/v1/tracking/campaign/${testCampaign.campaignId}`)
        .set('Authorization', `Bearer ${advertiserToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.totalPlays).toBe(3);
      expect(res.body.data.successfulPlays).toBe(2);
      expect(res.body.data.errorPlays).toBe(1);
      expect(parseFloat(res.body.data.totalAirTimeMinutes)).toBeCloseTo(1.0, 1);
    });

    test('GET /api/v1/tracking/campaign/99999 -> returns 404 for non-existent campaign', async () => {
      const res = await request(app)
        .get('/api/v1/tracking/campaign/99999')
        .set('Authorization', `Bearer ${advertiserToken}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Campaign not found');
    });
  });

  // ==========================================
  // SECTION 5: Billboard Hardware Logs & Dynamic Playlist
  // ==========================================
  describe('5. Billboard Hardware Logs & Dynamic Playlist API', () => {
    test('GET /api/v1/tracking/billboard/:id -> retrieves hardware play history', async () => {
      const res = await request(app)
        .get(`/api/v1/tracking/billboard/${ownerBillboard.billboardId}`)
        .set('Authorization', `Bearer ${ownerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(3);
    });

    test('GET /api/v1/scheduler/playlist/:id -> returns active dynamic schedule for Smart TV display', async () => {
      const res = await request(app)
        .get(`/api/v1/scheduler/playlist/${ownerBillboard.billboardId}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.billboardId).toBe(ownerBillboard.billboardId);
      expect(res.body.data.rotationMode).toBe('FAIR_ROUND_ROBIN');
    });
  });
});
