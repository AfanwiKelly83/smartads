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

describe('SMARTADS Backend Manage Profile API Test Suite', () => {
  let user1Token = '';
  let user1Email = 'user1.profile@smartads.com';
  let user2Token = '';
  let user2Email = 'user2.profile@smartads.com';

  beforeAll(async () => {
    // Register User 1
    const res1 = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Original User One',
        email: user1Email,
        password: 'Password123!',
        phoneNumber: '+237670000111',
        role: 'ADVERTISER'
      });
    user1Token = res1.body.data.token;

    // Register User 2
    const res2 = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Original User Two',
        email: user2Email,
        password: 'Password123!',
        phoneNumber: '+237670000222',
        role: 'ADVERTISER'
      });
    user2Token = res2.body.data.token;
  });

  test('1. GET /api/v1/users/profile without authentication token -> 401 Unauthorized', async () => {
    const res = await request(app).get('/api/v1/users/profile');

    expect(res.statusCode).toEqual(401);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Authentication token required');
  });

  test('2. GET /api/v1/users/profile with valid token -> 200 OK without password/hash', async () => {
    const res = await request(app)
      .get('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeDefined();
    expect(res.body.data.fullName).toEqual('Original User One');
    expect(res.body.data.email).toEqual(user1Email);
    expect(res.body.data.phoneNumber).toEqual('+237670000111');
    expect(res.body.data.role).toEqual('ADVERTISER');
    expect(res.body.data.password).toBeUndefined();
    expect(res.body.data.hash).toBeUndefined();
  });

  test('3. PUT /api/v1/users/profile updates fullName, email, and phoneNumber -> 200 OK', async () => {
    const updatedEmail = 'updated.user1@smartads.com';
    const res = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        fullName: 'Updated User One',
        email: updatedEmail,
        phoneNumber: '+237699999999'
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toContain('Profile updated');
    expect(res.body.data.fullName).toEqual('Updated User One');
    expect(res.body.data.email).toEqual(updatedEmail);
    expect(res.body.data.phoneNumber).toEqual('+237699999999');
    expect(res.body.data.password).toBeUndefined();

    user1Email = updatedEmail;
  });

  test('4. PUT /api/v1/users/profile with invalid email format -> 400 Bad Request', async () => {
    const res = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        email: 'not-an-email-address'
      });

    expect(res.statusCode).toEqual(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Invalid email');
  });

  test('5. PUT /api/v1/users/profile with duplicate email -> 409 Conflict', async () => {
    const res = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        email: user2Email
      });

    expect(res.statusCode).toEqual(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('already registered');
  });

  test('6. PUT /api/v1/users/profile cannot change restricted fields (userId, role, password, createdAt)', async () => {
    const originalProfileRes = await request(app)
      .get('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`);
    
    const originalUserId = originalProfileRes.body.data.userId;
    const originalRole = originalProfileRes.body.data.role;

    const res = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        userId: 99999,
        role: 'ADMIN',
        password: 'HackedPassword123!',
        createdAt: '2000-01-01T00:00:00.000Z',
        fullName: 'User One Restricted Test'
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.data.userId).toEqual(originalUserId);
    expect(res.body.data.role).toEqual(originalRole);
    expect(res.body.data.fullName).toEqual('User One Restricted Test');
    expect(res.body.data.password).toBeUndefined();

    // Verify password was not changed by trying to login with hacked password
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: user1Email,
        password: 'HackedPassword123!'
      });

    expect(loginRes.statusCode).toEqual(401);
  });
});
