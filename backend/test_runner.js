process.env.NODE_ENV = 'test';

const request = require('supertest');
const app = require('./src/app');
const { sequelize, User } = require('./src/models');
const assert = require('assert');

async function runTests() {
  console.log('--- Starting SMARTADS Manage Profile Direct Tests ---');
  try {
    await sequelize.sync({ force: true });
    
    // Register User 1 & User 2
    const res1 = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Original User One',
        email: 'user1.profile@smartads.com',
        password: 'Password123!',
        phoneNumber: '+237670000111',
        role: 'ADVERTISER'
      });
    assert.strictEqual(res1.statusCode, 201);
    const user1Token = res1.body.data.token;

    const res2 = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Original User Two',
        email: 'user2.profile@smartads.com',
        password: 'Password123!',
        phoneNumber: '+237670000222',
        role: 'ADVERTISER'
      });
    assert.strictEqual(res2.statusCode, 201);
    const user2Token = res2.body.data.token;

    // Test 1: GET /api/v1/users/profile without auth -> 401
    const test1 = await request(app).get('/api/v1/users/profile');
    assert.strictEqual(test1.statusCode, 401);
    assert.strictEqual(test1.body.success, false);
    console.log('✓ Test 1 Passed: GET profile without auth returns 401 Unauthorized');

    // Test 2: GET /api/v1/users/profile with valid token -> 200 (No password)
    const test2 = await request(app)
      .get('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`);
    assert.strictEqual(test2.statusCode, 200);
    assert.strictEqual(test2.body.success, true);
    assert.strictEqual(test2.body.data.fullName, 'Original User One');
    assert.strictEqual(test2.body.data.email, 'user1.profile@smartads.com');
    assert.strictEqual(test2.body.data.password, undefined);
    assert.strictEqual(test2.body.data.hash, undefined);
    console.log('✓ Test 2 Passed: GET profile returns user data without password/hash');

    // Test 3: PUT /api/v1/users/profile updates profile fields -> 200
    const updatedEmail = 'updated.user1@smartads.com';
    const test3 = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        fullName: 'Updated User One',
        email: updatedEmail,
        phoneNumber: '+237699999999'
      });
    assert.strictEqual(test3.statusCode, 200);
    assert.strictEqual(test3.body.success, true);
    assert.strictEqual(test3.body.data.fullName, 'Updated User One');
    assert.strictEqual(test3.body.data.email, updatedEmail);
    assert.strictEqual(test3.body.data.phoneNumber, '+237699999999');
    assert.strictEqual(test3.body.data.password, undefined);
    console.log('✓ Test 3 Passed: PUT profile updates fullName, email, phoneNumber');

    // Test 4: PUT /api/v1/users/profile invalid email -> 400
    const test4 = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        email: 'invalid-email-format'
      });
    assert.strictEqual(test4.statusCode, 400);
    assert.strictEqual(test4.body.success, false);
    console.log('✓ Test 4 Passed: PUT profile invalid email returns 400 Bad Request');

    // Test 5: PUT /api/v1/users/profile duplicate email -> 409
    const test5 = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        email: 'user2.profile@smartads.com'
      });
    assert.strictEqual(test5.statusCode, 409);
    assert.strictEqual(test5.body.success, false);
    console.log('✓ Test 5 Passed: PUT profile duplicate email returns 409 Conflict');

    // Test 6: PUT /api/v1/users/profile protected fields (userId, role, password) cannot be changed
    const test6 = await request(app)
      .put('/api/v1/users/profile')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({
        userId: 99999,
        role: 'ADMIN',
        password: 'HackedPassword123!',
        fullName: 'User One Protected Test'
      });
    assert.strictEqual(test6.statusCode, 200);
    assert.strictEqual(test6.body.data.userId, test2.body.data.userId);
    assert.strictEqual(test6.body.data.role, 'ADVERTISER');
    assert.strictEqual(test6.body.data.password, undefined);

    const loginCheck = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: updatedEmail,
        password: 'HackedPassword123!'
      });
    assert.strictEqual(loginCheck.statusCode, 401);
    console.log('✓ Test 6 Passed: Protected fields (userId, role, password) cannot be changed');

    console.log('--- ALL PROFILE TESTS PASSED SUCCESSFULLY! ---');
  } catch (err) {
    console.error('Test Failed:', err);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

runTests();
