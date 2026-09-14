const request = require('supertest');
const app = require('../src/app');
const { sequelize, User } = require('../src/models');

process.env.NODE_ENV = 'test';
jest.setTimeout(30000);

beforeAll(async () => {
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  await sequelize.close();
});

describe('SMARTADS Backend Authentication API Test Suite', () => {
  let adminToken = '';
  let advertiserToken = '';
  let userToken = '';
  let advertiserEmail = 'advertiser.flutter@smartads.com';

  test('1. Register successfully', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Flutter Advertiser',
        email: advertiserEmail,
        password: 'Password123!',
        role: 'ADVERTISER',
        phoneNumber: '+237670000100'
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.email).toEqual(advertiserEmail);
    expect(res.body.data.user.password).toBeUndefined();

    advertiserToken = res.body.data.token;
  });

  test('2. Register duplicate email -> HTTP 409 Conflict', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Duplicate User',
        email: advertiserEmail,
        password: 'Password123!'
      });

    expect(res.statusCode).toEqual(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('already registered');
  });

  test('3. Register validation error -> HTTP 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email: 'incomplete@smartads.com'
      });

    expect(res.statusCode).toEqual(400);
    expect(res.body.success).toBe(false);
  });

  test('4. Login successfully -> HTTP 200 OK', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: advertiserEmail,
        password: 'Password123!'
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.email).toEqual(advertiserEmail);
    expect(res.body.data.user.password).toBeUndefined();
  });

  test('5. Wrong password -> HTTP 401 Unauthorized', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: advertiserEmail,
        password: 'WrongPassword999!'
      });

    expect(res.statusCode).toEqual(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Invalid email or password');
  });

  test('6. Missing token -> HTTP 401 Unauthorized', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me');

    expect(res.statusCode).toEqual(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('token required');
  });

  test('7. Invalid token -> HTTP 401 Unauthorized', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer invalid_jwt_token_12345');

    expect(res.statusCode).toEqual(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Invalid or expired');
  });

  test('8. GET /api/v1/auth/me with valid token -> HTTP 200 OK', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${advertiserToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.email).toEqual(advertiserEmail);
    expect(res.body.data.password).toBeUndefined();
  });

  test('8a. PUT /api/v1/auth/me updates profile fields -> HTTP 200 OK', async () => {
    const res = await request(app)
      .put('/api/v1/auth/me')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        fullName: 'Flutter Advertiser Updated',
        phoneNumber: '+237670000199'
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toContain('Profile updated');
    expect(res.body.data.fullName).toEqual('Flutter Advertiser Updated');
    expect(res.body.data.phoneNumber).toEqual('+237670000199');
  });

  test('8b. POST /api/v1/auth/change-password requires current password and updates hash -> HTTP 200 OK', async () => {
    const changePasswordRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        currentPassword: 'Password123!',
        newPassword: 'NewPassword456!'
      });

    expect(changePasswordRes.statusCode).toEqual(200);
    expect(changePasswordRes.body.success).toBe(true);
    expect(changePasswordRes.body.message).toContain('Password changed');

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: advertiserEmail,
        password: 'NewPassword456!'
      });

    expect(loginRes.statusCode).toEqual(200);
    expect(loginRes.body.success).toBe(true);
  });

  test('9. Admin authorization check', async () => {
    // Register Admin
    const adminRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Admin User',
        email: 'admin.flutter@smartads.com',
        password: 'AdminPassword123!',
        role: 'ADMIN'
      });

    expect(adminRes.statusCode).toEqual(201);
    adminToken = adminRes.body.data.token;

    // Admin accessing Admin route (POST /api/v1/billboards) -> Allowed (201 Created)
    const billboardRes = await request(app)
      .post('/api/v1/billboards')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        billboardName: 'Admin Created Billboard',
        location: 'Downtown'
      });

    expect(billboardRes.statusCode).toEqual(201);
  });

  test('10. Advertiser authorization check -> HTTP 403 Forbidden on Admin route', async () => {
    // Advertiser accessing Admin route -> Forbidden (403)
    const res = await request(app)
      .post('/api/v1/billboards')
      .set('Authorization', `Bearer ${advertiserToken}`)
      .send({
        billboardName: 'Advertiser Forbidden Billboard',
        location: 'Downtown'
      });

    expect(res.statusCode).toEqual(403);
    expect(res.body.success).toBe(false);
  });

  test('11. Normal user receives USER role and cannot create campaigns or bookings', async () => {
    const registerRes = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Normal User',
        email: 'user.flutter@smartads.com',
        password: 'UserPassword123!',
        role: 'USER'
      });

    expect(registerRes.statusCode).toEqual(201);
    expect(registerRes.body.data.user.role).toEqual('USER');
    userToken = registerRes.body.data.token;

    const campaignRes = await request(app)
      .post('/api/v1/campaigns')
      .set('Authorization', `Bearer ${userToken}`)
      .send({});
    expect(campaignRes.statusCode).toEqual(403);

    const bookingRes = await request(app)
      .post('/api/v1/bookings')
      .set('Authorization', `Bearer ${userToken}`)
      .send({});
    expect(bookingRes.statusCode).toEqual(403);
  });
});
