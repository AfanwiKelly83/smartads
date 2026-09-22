process.env.NODE_ENV = 'test';
const request = require('supertest');
const app = require('../src/app');
const { sequelize, User, Billboard, Booking, Campaign, Advertisement } = require('../src/models');
const jwt = require('jsonwebtoken');

jest.setTimeout(30000);

describe('Billboard Capacity Management and Dynamic Playlist API', () => {
  let adminToken, advertiserToken;
  let adminUser, advertiserUser;
  let testBillboard;

  beforeAll(async () => {
    await sequelize.sync({ force: true });

    adminUser = await User.create({
      fullName: 'Super Admin',
      email: 'admin_cap@smartads.cm',
      password: 'password123',
      role: 'ADMIN',
      accountStatus: 'ACTIVE'
    });

    advertiserUser = await User.create({
      fullName: 'Advertiser Alpha',
      email: 'advertiser_cap@smartads.cm',
      password: 'password123',
      role: 'ADVERTISER',
      accountStatus: 'ACTIVE'
    });

    const jwtSecret = process.env.JWT_SECRET || 'smartads_jwt_secret_dev_key_2026';
    adminToken = jwt.sign({ userId: adminUser.userId, role: 'ADMIN' }, jwtSecret, { expiresIn: '1d' });
    advertiserToken = jwt.sign({ userId: advertiserUser.userId, role: 'ADVERTISER' }, jwtSecret, { expiresIn: '1d' });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  test('1. Create billboard with maxActiveCampaigns = 3', async () => {
    const res = await request(app)
      .post('/api/v1/billboards')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        billboardName: 'Douala Premium Screen',
        location: 'Akwa Boulevard, Douala',
        pricePerHour: 12000,
        maxActiveCampaigns: 3
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.maxActiveCampaigns).toBe(3);
    testBillboard = res.body.data;
  });

  test('2. Availability query shows 0 occupied and 3 remaining slots', async () => {
    const res = await request(app)
      .get(`/api/v1/billboards/${testBillboard.billboardId}/availability?startDate=2026-10-01&endDate=2026-10-05`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.maxActiveCampaigns).toBe(3);
    expect(res.body.data.occupiedCampaignsCount).toBe(0);
    expect(res.body.data.remainingCapacity).toBe(3);
    expect(res.body.data.isAvailable).toBe(true);
  });

  test('3. Booking 1, 2, 3 on same dates succeed (reaching capacity)', async () => {
    for (let i = 1; i <= 3; i++) {
      const res = await request(app)
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${advertiserToken}`)
        .send({
          billboardId: testBillboard.billboardId,
          startDate: '2026-10-01',
          endDate: '2026-10-05',
          amount: 50000
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    }
  });

  test('4. Availability query now shows 3 occupied and 0 remaining slots', async () => {
    const res = await request(app)
      .get(`/api/v1/billboards/${testBillboard.billboardId}/availability?startDate=2026-10-01&endDate=2026-10-05`);

    expect(res.status).toBe(200);
    expect(res.body.data.occupiedCampaignsCount).toBe(3);
    expect(res.body.data.remainingCapacity).toBe(0);
    expect(res.body.data.isAvailable).toBe(false);
  });

  test('5. Booking 4 on overlapping dates (2026-10-03 to 2026-10-07) is REJECTED with 409', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId: testBillboard.billboardId,
        startDate: '2026-10-03',
        endDate: '2026-10-07',
        amount: 50000
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message.toLowerCase()).toContain('capacity');
  });

  test('6. Booking 4 on non-overlapping dates (2026-10-10 to 2026-10-15) SUCCEEDS', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId: testBillboard.billboardId,
        startDate: '2026-10-10',
        endDate: '2026-10-15',
        amount: 60000
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });

  test('7. Dynamic playlist returns active campaigns in round-robin sequence', async () => {
    const today = new Date().toISOString().split('T')[0];
    const bookingRes = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId: testBillboard.billboardId,
        startDate: today,
        endDate: today,
        amount: 25000
      });

    expect(bookingRes.status).toBe(201);
    const bookingId = bookingRes.body.data.bookingId;

    await Booking.update({ status: 'CONFIRMED' }, { where: { bookingId } });

    await Advertisement.create({
      advertiserId: advertiserUser.userId,
      title: 'Coca-Cola Promo 30s',
      mediaType: 'VIDEO',
      filePath: '/uploads/cocacola.mp4',
      fileSize: 6 * 1024 * 1024,
      approvalStatus: 'APPROVED'
    });

    const playlistRes = await request(app)
      .get(`/api/v1/scheduler/playlist/${testBillboard.billboardId}`);

    expect(playlistRes.status).toBe(200);
    expect(playlistRes.body.success).toBe(true);
    expect(playlistRes.body.data.billboardId).toBe(testBillboard.billboardId);
    expect(playlistRes.body.data.activeCampaignsCount).toBeGreaterThanOrEqual(1);
    expect(playlistRes.body.data.rotationMode).toBe('FAIR_ROUND_ROBIN');
    expect(playlistRes.body.data.playlist[0].durationSeconds).toBeGreaterThan(0);
  });
});
