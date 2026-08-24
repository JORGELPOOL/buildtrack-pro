process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const fs = require('fs');
const path = require('path');
const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, staffAuthHeader, cleanupUploads, uploadsDirectory } = require('./helpers/testUtils');

const fixturePath = path.resolve(__dirname, 'fixtures/photo.txt');

describe('Photo routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  afterEach(() => {
    cleanupUploads();
  });

  it('uploads, lists, and deletes project photos', async () => {
    const project = db.__seedProject({ status: 'active' });

    const uploadResponse = await request(app)
      .post(`/api/projects/${project.id}/photos`)
      .set('Authorization', staffAuthHeader())
      .field('caption', 'Site progress')
      .attach('photo', fixturePath);

    expect(uploadResponse.status).toBe(201);
    expect(uploadResponse.body.original_name).toBe('photo.txt');
    expect(fs.existsSync(path.join(uploadsDirectory, uploadResponse.body.filename))).toBe(true);

    const listResponse = await request(app)
      .get(`/api/projects/${project.id}/photos`)
      .set('Authorization', adminAuthHeader());
    expect(listResponse.status).toBe(200);
    expect(listResponse.body).toHaveLength(1);

    const deleteResponse = await request(app)
      .delete(`/api/photos/${uploadResponse.body.id}`)
      .set('Authorization', adminAuthHeader());
    expect(deleteResponse.status).toBe(204);
  });
});
