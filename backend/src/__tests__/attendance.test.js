process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, staffAuthHeader, cleanupUploads } = require('./helpers/testUtils');

describe('Attendance routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  it('creates, lists, updates, and deletes attendance records', async () => {
    const project = db.__seedProject({ status: 'active' });

    const createResponse = await request(app)
      .post(`/api/projects/${project.id}/attendance`)
      .set('Authorization', staffAuthHeader())
      .send({
        worker_name: 'Alex Mason',
        date: '2026-06-15',
        check_in: '08:00',
        check_out: '17:30',
        notes: 'Foundation team'
      });

    expect(createResponse.status).toBe(201);
    expect(createResponse.body.hours_worked).toBe(9.5);

    const listResponse = await request(app)
      .get(`/api/projects/${project.id}/attendance`)
      .set('Authorization', adminAuthHeader());
    expect(listResponse.status).toBe(200);
    expect(listResponse.body).toHaveLength(1);

    const recordId = createResponse.body.id;
    const updateResponse = await request(app)
      .put(`/api/attendance/${recordId}`)
      .set('Authorization', staffAuthHeader())
      .send({
        worker_name: 'Alex Mason',
        date: '2026-06-15',
        check_in: '08:00',
        check_out: '16:00',
        notes: 'Shift updated'
      });

    expect(updateResponse.status).toBe(200);
    expect(updateResponse.body.hours_worked).toBe(8);

    const deleteResponse = await request(app)
      .delete(`/api/attendance/${recordId}`)
      .set('Authorization', adminAuthHeader());
    expect(deleteResponse.status).toBe(204);
  });
});
