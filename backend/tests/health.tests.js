const request = require('supertest');
const app = require('../src/app');
const sequelize = require('../src/config/database');

describe('Backend API Integration Tests', () => {
  beforeAll(async () => {
    // Ensure test environment
    process.env.NODE_ENV = 'test';
    await sequelize.sync({ force: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('GET /api/health', () => {
    it('should return 200 OK with server health metadata', async () => {
      const response = await request(app)
        .get('/api/health')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message', 'Smart Digital Billboard API is running');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });
  });

  describe('GET /api/health/db', () => {
    it('should return 200 OK with database connection status', async () => {
      const response = await request(app)
        .get('/api/health/db')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message', 'Database connection established successfully');
      expect(response.body).toHaveProperty('dialect', 'sqlite');
    });
  });

  describe('GET /health (Legacy endpoint)', () => {
    it('should return 200 OK with legacy message', async () => {
      const response = await request(app)
        .get('/health')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body).toEqual({ message: 'the backend is running' });
    });
  });

  describe('404 Not Found', () => {
    it('should return 404 for unknown endpoints', async () => {
      const response = await request(app)
        .get('/api/non-existent-route')
        .expect('Content-Type', /json/)
        .expect(404);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body.message).toContain('not found');
    });
  });
});
