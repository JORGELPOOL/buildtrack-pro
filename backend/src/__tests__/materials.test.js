process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, staffAuthHeader, cleanupUploads } = require('./helpers/testUtils');

describe('Materials routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  it('creates, lists, updates, and deletes project materials', async () => {
    const project = db.__seedProject({ status: 'active' });

    const createResponse = await request(app)
      .post(`/api/projects/${project.id}/materials`)
      .set('Authorization', staffAuthHeader())
      .send({
        name: 'Bricks',
        quantity: 500,
        unit: 'pcs',
        unit_cost: 1.2,
        supplier: 'Brick Depot',
        status: 'ordered',
        date_ordered: '2026-07-01'
      });

    expect(createResponse.status).toBe(201);
    expect(createResponse.body.total_cost).toBe(600);

    const listResponse = await request(app)
      .get(`/api/projects/${project.id}/materials`)
      .set('Authorization', adminAuthHeader());
    expect(listResponse.status).toBe(200);
    expect(listResponse.body).toHaveLength(1);

    const materialId = createResponse.body.id;
    const updateResponse = await request(app)
      .put(`/api/materials/${materialId}`)
      .set('Authorization', staffAuthHeader())
      .send({
        name: 'Bricks',
        quantity: 600,
        unit: 'pcs',
        unit_cost: 1.1,
        supplier: 'Brick Depot',
        status: 'delivered',
        date_ordered: '2026-07-01',
        date_delivered: '2026-07-05'
      });

    expect(updateResponse.status).toBe(200);
    expect(updateResponse.body.status).toBe('delivered');
    expect(updateResponse.body.total_cost).toBe(660);

    const deleteResponse = await request(app)
      .delete(`/api/materials/${materialId}`)
      .set('Authorization', adminAuthHeader());
    expect(deleteResponse.status).toBe(204);
  });
});
