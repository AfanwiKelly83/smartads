const request = require('supertest');
const app = require('../src/app');
const { sequelize, User, Billboard, Advertisement, Booking, Campaign, Payment, IoTDevice } = require('../src/models');

describe('SmartAds End-to-End Billboard Owner & AI Workflow Tests', () => {
  let ownerToken, ownerId;
  let owner2Token, owner2Id;
  let adminToken, adminId;
  let advertiserToken, advertiserId;
  let createdBillboardId, createdBillboardCode;
  let createdBookingId;
  let createdAdId;

  beforeAll(async () => {
    await sequelize.sync({ force: true });

    // 1. Create Admin
    const adminRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Admin User',
        email: 'admin@smartads.cm',
        password: 'AdminPassword123!',
        role: 'ADMIN'
      });
    adminToken = adminRes.body.data.token;
    adminId = adminRes.body.data.user.userId;

    // 2. Register Billboard Owner via dedicated endpoint
    const ownerRes = await request(app)
      .post('/api/v1/auth/register-owner')
      .send({
        fullName: 'Jean Owner',
        email: 'owner1@smartads.cm',
        password: 'OwnerPassword123!',
        phoneNumber: '+237670000001'
      });
    expect(ownerRes.status).toBe(201);
    expect(ownerRes.body.data.user.role).toBe('BILLBOARD_OWNER');
    ownerToken = ownerRes.body.data.token;
    ownerId = ownerRes.body.data.user.userId;

    // 3. Register second Owner for authorization testing
    const owner2Res = await request(app)
      .post('/api/v1/auth/register-owner')
      .send({
        fullName: 'Paul Owner 2',
        email: 'owner2@smartads.cm',
        password: 'OwnerPassword123!',
        phoneNumber: '+237670000002'
      });
    owner2Token = owner2Res.body.data.token;
    owner2Id = owner2Res.body.data.user.userId;

    // 4. Register Advertiser
    const advertiserRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Mega Brand Advertiser',
        email: 'advertiser@megabrand.com',
        password: 'AdPassword123!',
        role: 'ADVERTISER'
      });
    advertiserToken = advertiserRes.body.data.token;
    advertiserId = advertiserRes.body.data.user.userId;
  });

  afterAll(async () => {
    await sequelize.close();
  });

  test('TEST 1: Owner creates a Billboard -> gets unique ID BILL-xxx, QR code, and PENDING_APPROVAL status', async () => {
    const res = await request(app)
      .post('/api/v1/billboards')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        billboardName: 'Omnisport LED Screen 1',
        location: 'Omnisport Stadium, Yaoundé',
        address: 'Rue 124, Omnisport, Yaoundé',
        description: 'Prime high-definition digital screen located at stadium entrance.',
        billboardType: 'DIGITAL_LED',
        width: '1920',
        height: '1080',
        resolution: '1920x1080',
        pricePerHour: 20000,
        operatingHours: '06:00 - 23:00',
        latitude: 3.8767,
        longitude: 11.5342
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.approvalStatus).toBe('PENDING_APPROVAL');
    expect(res.body.data.billboardCode).toMatch(/^BILL-\d{3}$/);
    expect(res.body.data.qrCode).toBeDefined();
    expect(res.body.data.ownerId).toBe(ownerId);

    createdBillboardId = res.body.data.billboardId;
    createdBillboardCode = res.body.data.billboardCode;
  });

  test('TEST 2: Public / Advertiser search does NOT return PENDING_APPROVAL billboard', async () => {
    const res = await request(app)
      .get('/api/v1/billboards')
      .set('Authorization', `Bearer ${advertiserToken}`);

    expect(res.status).toBe(200);
    const found = res.body.data.some(b => b.billboardId === createdBillboardId);
    expect(found).toBe(false);
  });

  test('TEST 3: Admin approves the billboard -> status becomes APPROVED', async () => {
    const res = await request(app)
      .put(`/api/v1/billboards/${createdBillboardId}/approval`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        status: 'APPROVED',
        notes: 'Verified location and technical specifications.'
      });

    expect(res.status).toBe(200);
    expect(res.body.data.approvalStatus).toBe('APPROVED');
  });

  test('TEST 4: Public / Advertiser search now finds the APPROVED billboard', async () => {
    const res = await request(app)
      .get('/api/v1/billboards')
      .set('Authorization', `Bearer ${advertiserToken}`);

    expect(res.status).toBe(200);
    const found = res.body.data.find(b => b.billboardId === createdBillboardId);
    expect(found).toBeDefined();
    expect(found.billboardName).toBe('Omnisport LED Screen 1');
  });

  test('TEST 5: QR Code lookup by billboardCode (e.g. BILL-001) returns exact billboard', async () => {
    const res = await request(app)
      .get(`/api/v1/billboards/${createdBillboardCode}`);

    expect(res.status).toBe(200);
    expect(res.body.data.billboardId).toBe(createdBillboardId);
    expect(res.body.data.billboardCode).toBe(createdBillboardCode);
  });

  test('TEST 6: Advertiser uploads safe ad -> Gemini AI verification returns AI_APPROVED', async () => {
    const res = await request(app)
      .post('/api/v1/advertisements')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        title: 'Fresh Juice Summer Refresh Promo',
        mediaType: 'IMAGE',
        mediaUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800',
        playStartTime: '08:00',
        playEndTime: '12:00'
      });

    expect(res.status).toBe(201);
    expect(res.body.data.approvalStatus).toBe('AI_APPROVED');
    createdAdId = res.body.data.advertisementId;
  });

  test('TEST 7: AI flags questionable ad -> AI_FLAGGED -> Admin reviews and approves', async () => {
    const flagRes = await request(app)
      .post('/api/v1/advertisements')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        title: 'Review Questionable Promo Campaign',
        mediaType: 'IMAGE',
        mediaUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800'
      });

    expect(flagRes.status).toBe(201);
    expect(flagRes.body.data.approvalStatus).toBe('AI_FLAGGED');
    const flaggedAdId = flagRes.body.data.advertisementId;

    // Admin reviews and approves
    const reviewRes = await request(app)
      .put(`/api/v1/advertisements/${flaggedAdId}/admin-review`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        action: 'APPROVE',
        notes: 'Reviewed and confirmed safe by Admin.'
      });

    expect(reviewRes.status).toBe(200);
    expect(reviewRes.body.data.approvalStatus).toBe('APPROVED');
  });

  test('TEST 8: Advertiser books billboard -> Payment succeeds -> Campaign & Booking CONFIRMED', async () => {
    const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
    const dayAfter = new Date(Date.now() + 172800000).toISOString().slice(0, 10);

    const bookingRes = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId: createdBillboardId,
        startDate: tomorrow,
        endDate: dayAfter,
        startTime: '10:00',
        endTime: '14:00'
      });

    expect(bookingRes.status).toBe(201);
    expect(bookingRes.body.data.status).toBe('PENDING');
    createdBookingId = bookingRes.body.data.bookingId;

    // Process payment
    const paymentRes = await request(app)
      .post('/api/v1/payments')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        bookingId: createdBookingId,
        paymentMethod: 'DIGIPAY'
      });

    expect(paymentRes.status).toBe(201);
    expect(paymentRes.body.data.paymentStatus).toBe('SUCCESSFUL');

    // Verify booking is confirmed
    const getBooking = await request(app)
      .get(`/api/v1/bookings/${createdBookingId}`)
      .set('Authorization', `Bearer ${advertiserToken}`);

    expect(getBooking.body.data.status).toBe('CONFIRMED');
  });

  test('TEST 9: Owner A owns billboard -> Owner B cannot modify Owner A billboard (HTTP 403)', async () => {
    const res = await request(app)
      .put(`/api/v1/billboards/${createdBillboardId}`)
      .set('Authorization', `Bearer ${owner2Token}`)
      .send({
        billboardName: 'Malicious Hijack Attempt'
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('TEST 10: Double booking prevention -> Conflicting confirmed slot is rejected (HTTP 409)', async () => {
    const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
    const dayAfter = new Date(Date.now() + 172800000).toISOString().slice(0, 10);

    const res = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardId: createdBillboardId,
        startDate: tomorrow,
        endDate: dayAfter,
        startTime: '10:00',
        endTime: '14:00'
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/conflict/i);
  });

  test('TEST 11: Billboard Owner views own bookings, earnings, and IoT telemetry', async () => {
    // 1. Owner Bookings
    const bookingsRes = await request(app)
      .get('/api/v1/bookings/owner-bookings')
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(bookingsRes.status).toBe(200);
    expect(bookingsRes.body.data.length).toBeGreaterThan(0);
    expect(bookingsRes.body.data[0].billboardId).toBe(createdBillboardId);

    // 2. Owner Earnings
    const earningsRes = await request(app)
      .get('/api/v1/payments/owner-earnings')
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(earningsRes.status).toBe(200);
    expect(earningsRes.body.data.totalEarnings).toBeGreaterThan(0);

    // 3. IoT Heartbeat and Owner IoT Device view
    await request(app)
      .post('/api/v1/iot/heartbeat')
      .send({
        billboardId: createdBillboardId,
        macAddress: 'AA:BB:CC:DD:EE:01',
        firmwareVersion: 'v2.1.0-esp32',
        connectionStatus: 'ONLINE'
      });

    const iotRes = await request(app)
      .get('/api/v1/iot/devices')
      .set('Authorization', `Bearer ${ownerToken}`);

    expect(iotRes.status).toBe(200);
    expect(iotRes.body.data.length).toBe(1);
    expect(iotRes.body.data[0].billboardId).toBe(createdBillboardId);

    // Owner 2 sees 0 devices because they own no billboards with IoT
    const iot2Res = await request(app)
      .get('/api/v1/iot/devices')
      .set('Authorization', `Bearer ${owner2Token}`);

    expect(iot2Res.status).toBe(200);
    expect(iot2Res.body.data.length).toBe(0);
  });
});
