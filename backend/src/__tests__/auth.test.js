process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, staffAuthHeader, cleanupUploads } = require('./helpers/testUtils');

describe('Auth routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  afterEach(() => {
    cleanupUploads();
  });

  it('logs in successfully with valid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'admin@buildtrack.com', password: 'Admin@123' });

    expect(response.status).toBe(200);
    expect(response.body.token).toBeTruthy();
    expect(response.body.user).toMatchObject({ email: 'admin@buildtrack.com', role: 'admin' });
  });

  it('rejects invalid login credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'admin@buildtrack.com', password: 'wrong-password' });

    expect(response.status).toBe(401);
    expect(response.body.message).toBe('Invalid email or password');
  });

  it('allows admins to create staff accounts', async () => {
    const response = await request(app)
      .post('/api/auth/staff')
      .set('Authorization', adminAuthHeader())
      .send({ email: 'newstaff@buildtrack.com', password: 'Staff@123' });

    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({ email: 'newstaff@buildtrack.com', role: 'staff' });
  });

  it('blocks staff users from creating staff accounts', async () => {
    const response = await request(app)
      .post('/api/auth/staff')
      .set('Authorization', staffAuthHeader())
      .send({ email: 'blocked@buildtrack.com', password: 'Staff@123' });

    expect(response.status).toBe(403);
    expect(response.body.message).toBe('Admin access required');
  });
});
