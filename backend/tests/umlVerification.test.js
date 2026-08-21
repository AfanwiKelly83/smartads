const request = require('supertest');
const app = require('../src/app');
const {
  sequelize,
  User,
  Billboard,
  Advertisement,
  Campaign,
  CampaignBillboard,
  Booking,
  Payment,
  Notification,
  IoTDevice,
  PlaybackLog
} = require('../src/models');

process.env.NODE_ENV = 'test';
jest.setTimeout(30000);

beforeAll(async () => {
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  await sequelize.close();
});

describe('SMARTADS UML Verification Test Suite', () => {
  let adminToken = '';
  let advertiserToken = '';
  let adminUserId = null;
  let advertiserUserId = null;
  let billboardId = null;
  let adId = null;
  let campaignId = null;
  let bookingId = null;

  test('1. Database Tables & Schema Verification', async () => {
    const models = sequelize.models;
    expect(models.User).toBeDefined();
    expect(models.Billboard).toBeDefined();
    expect(models.Advertisement).toBeDefined();
    expect(models.Campaign).toBeDefined();
    expect(models.CampaignBillboard).toBeDefined();
    expect(models.Booking).toBeDefined();
    expect(models.Payment).toBeDefined();
    expect(models.Notification).toBeDefined();
    expect(models.IoTDevice).toBeDefined();
    expect(models.PlaybackLog).toBeDefined();
  });

  test('2. User Registration & Role Assignment', async () => {
    // Admin Creation
    const adminRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'System Administrator',
        email: 'admin@smartads.com',
        password: 'AdminPassword123!',
        role: 'ADMIN',
        phoneNumber: '+237670000001'
      });

    expect(adminRes.statusCode).toEqual(201);
    adminToken = adminRes.body.data.token;
    adminUserId = adminRes.body.data.user.userId;
    expect(adminRes.body.data.user.role).toEqual('ADMIN');

    // Advertiser Creation
    const advRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Brand Advertiser',
        email: 'advertiser@brand.com',
        password: 'AdvertiserPassword123!',
        role: 'ADVERTISER',
        phoneNumber: '+237670000002'
      });

    expect(advRes.statusCode).toEqual(201);
    advertiserToken = advRes.body.data.token;
    advertiserUserId = advRes.body.data.user.userId;
    expect(advRes.body.data.user.role).toEqual('ADVERTISER');
  });

  test('3. Admin Can Create Billboard & Automatic QR Generation', async () => {
    const res = await request(app)
      .post('/api/v1/billboards')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        billboardName: 'Yaounde City Center Display',
        location: 'Avenue Kennedy',
        pricePerHour: 15.0,
        resolution: '1920x1080'
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.createdBy).toEqual(adminUserId);
    expect(res.body.data.qrCode).toBeDefined();
    expect(res.body.data.qrCode).toContain('/uploads/qrcodes/qr_billboard_');

    billboardId = res.body.data.billboardId;
  });

  test('4. Advertiser Receives 403 Forbidden When Creating Billboard', async () => {
    const res = await request(app)
      .post('/api/v1/billboards')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardName: 'Unauthorized Billboard Attempt',
        location: 'Forbidden Zone'
      });

    expect(res.statusCode).toEqual(403);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Forbidden');
  });

  test('5. Advertiser Uploads Advertisement & Gemini AI Verification', async () => {
    const ad = await Advertisement.create({
      advertiserId: advertiserUserId,
      title: 'Coca-Cola Summer Campaign',
      mediaType: 'IMAGE',
      filePath: '/uploads/ads/sample_coke.jpg',
      fileSize: 1024500,
      uploadDate: new Date(),
      approvalStatus: 'APPROVED',
      playStartTime: '08:00',
      playEndTime: '20:00'
    });

    expect(ad.advertisementId).toBeDefined();
    adId = ad.advertisementId;
  });

  test('6. Campaign & CampaignBillboard M:N Junction Verification', async () => {
    const campRes = await request(app)
      .post('/api/v1/campaigns')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        campaignType: 'DIGITAL_OUTDOOR',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        repeatOption: 'DAILY',
        billboardIds: [billboardId]
      });

    expect(campRes.statusCode).toEqual(201);
    campaignId = campRes.body.data.campaignId;

    const cbLink = await CampaignBillboard.findOne({
      where: { campaignId, billboardId }
    });
    expect(cbLink).not.toBeNull();
  });

  test('7. Booking Creation & Availability Overlap Detection', async () => {
    const bookingRes = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId,
        campaignId,
        startDate: '2026-10-01',
        endDate: '2026-10-15',
        startTime: '08:00',
        endTime: '20:00',
        repeatOption: 'DAILY'
      });

    expect(bookingRes.statusCode).toEqual(201);
    expect(bookingRes.body.data.status).toEqual('PENDING');
    bookingId = bookingRes.body.data.bookingId;

    const overlapRes = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId,
        campaignId,
        startDate: '2026-10-05',
        endDate: '2026-10-20',
        startTime: '08:00',
        endTime: '20:00',
        repeatOption: 'DAILY'
      });

    expect(overlapRes.statusCode).toEqual(409);
    expect(overlapRes.body.success).toBe(false);
  });

  test('8. Payment Belongs to Booking (DigiPay Integration)', async () => {
    const payRes = await request(app)
      .post('/api/v1/payments')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        bookingId,
        paymentMethod: 'DIGIPAY'
      });

    expect(payRes.statusCode).toEqual(201);
    expect(payRes.body.data.bookingId).toEqual(bookingId);
    expect(payRes.body.data.paymentStatus).toEqual('SUCCESSFUL');
    expect(payRes.body.data.transactionReference).toContain('DIGIPAY-');

    const updatedBooking = await Booking.findByPk(bookingId);
    expect(updatedBooking.status).toEqual('CONFIRMED');
  });

  test('9. User Notifications', async () => {
    const notifRes = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${advertiserToken}`);

    expect(notifRes.statusCode).toEqual(200);
    expect(notifRes.body.data.length).toBeGreaterThan(0);
    expect(notifRes.body.data[0].userId).toEqual(advertiserUserId);
  });

  test('10. IoT Device Association with Billboard', async () => {
    const iotDevice = await IoTDevice.create({
      billboardId,
      macAddress: '00:1A:2B:3C:4D:5E',
      firmwareVersion: '2.1.0',
      connectionStatus: 'CONNECTED'
    });

    expect(iotDevice.deviceId).toBeDefined();
    expect(iotDevice.billboardId).toEqual(billboardId);
  });

  test('11. Admin Statistics Service (No Fake Stats Table)', async () => {
    const statsRes = await request(app)
      .get('/api/v1/analytics')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(statsRes.statusCode).toEqual(200);
    expect(statsRes.body.data.users.admins).toBeGreaterThanOrEqual(1);
    expect(statsRes.body.data.billboards.total).toBeGreaterThanOrEqual(1);
    expect(statsRes.body.data.financials.totalRevenue).toBeGreaterThan(0);
  });
});
