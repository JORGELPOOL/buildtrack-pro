process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, staffAuthHeader, cleanupUploads } = require('./helpers/testUtils');

describe('Budget and expenses routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  it('manages project budgets and expenses', async () => {
    const project = db.__seedProject({ status: 'active' });

    const budgetResponse = await request(app)
      .post(`/api/projects/${project.id}/budget`)
      .set('Authorization', adminAuthHeader())
      .send({ total_budget: 1000 });

    expect(budgetResponse.status).toBe(200);
    expect(budgetResponse.body).toEqual({ total_budget: 1000, spent_amount: 0, remaining_amount: 1000 });

    const expenseResponse = await request(app)
      .post(`/api/projects/${project.id}/expenses`)
      .set('Authorization', staffAuthHeader())
      .send({ category: 'Materials', description: 'Steel rods', amount: 250, date: '2026-05-01' });

    expect(expenseResponse.status).toBe(201);
    expect(expenseResponse.body.amount).toBe(250);

    const listResponse = await request(app)
      .get(`/api/projects/${project.id}/expenses`)
      .set('Authorization', adminAuthHeader());
    expect(listResponse.status).toBe(200);
    expect(listResponse.body).toHaveLength(1);

    const expenseId = expenseResponse.body.id;
    const updateResponse = await request(app)
      .put(`/api/expenses/${expenseId}`)
      .set('Authorization', adminAuthHeader())
      .send({ category: 'Materials', description: 'Steel rods - revised', amount: 300, date: '2026-05-02' });

    expect(updateResponse.status).toBe(200);
    expect(updateResponse.body.amount).toBe(300);

    const summaryResponse = await request(app)
      .get(`/api/projects/${project.id}/budget`)
      .set('Authorization', adminAuthHeader());
    expect(summaryResponse.status).toBe(200);
    expect(summaryResponse.body).toEqual({ total_budget: 1000, spent_amount: 300, remaining_amount: 700 });

    const deleteResponse = await request(app)
      .delete(`/api/expenses/${expenseId}`)
      .set('Authorization', adminAuthHeader());
    expect(deleteResponse.status).toBe(204);
  });
});
