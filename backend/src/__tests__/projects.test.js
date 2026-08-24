process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, cleanupUploads } = require('./helpers/testUtils');

describe('Project routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  it('requires auth and supports project CRUD for admins', async () => {
    const unauthenticated = await request(app).get('/api/projects');
    expect(unauthenticated.status).toBe(401);

    const createResponse = await request(app)
      .post('/api/projects')
      .set('Authorization', adminAuthHeader())
      .send({
        name: 'Metro Station Upgrade',
        description: 'Civil and electrical works',
        client_name: 'City Transit',
        start_date: '2026-04-01',
        end_date: '2026-10-01',
        status: 'active'
      });

    expect(createResponse.status).toBe(201);
    expect(createResponse.body.name).toBe('Metro Station Upgrade');

    const projectId = createResponse.body.id;

    const listResponse = await request(app)
      .get('/api/projects')
      .set('Authorization', adminAuthHeader());
    expect(listResponse.status).toBe(200);
    expect(listResponse.body).toHaveLength(1);

    const detailResponse = await request(app)
      .get(`/api/projects/${projectId}`)
      .set('Authorization', adminAuthHeader());
    expect(detailResponse.status).toBe(200);
    expect(detailResponse.body.client_name).toBe('City Transit');

    const updateResponse = await request(app)
      .put(`/api/projects/${projectId}`)
      .set('Authorization', adminAuthHeader())
      .send({
        name: 'Metro Station Upgrade - Phase 2',
        description: 'Expanded scope',
        client_name: 'City Transit',
        start_date: '2026-04-01',
        end_date: '2026-12-15',
        status: 'completed'
      });

    expect(updateResponse.status).toBe(200);
    expect(updateResponse.body.status).toBe('completed');

    const deleteResponse = await request(app)
      .delete(`/api/projects/${projectId}`)
      .set('Authorization', adminAuthHeader());
    expect(deleteResponse.status).toBe(204);

    const missingResponse = await request(app)
      .get(`/api/projects/${projectId}`)
      .set('Authorization', adminAuthHeader());
    expect(missingResponse.status).toBe(404);
  });
});
