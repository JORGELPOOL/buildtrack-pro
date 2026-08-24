process.env.JWT_SECRET = 'test-secret';

jest.mock('../config/db', () => require('./helpers/mockDb'));

const request = require('supertest');
const app = require('../app');
const db = require('../config/db');
const { adminAuthHeader, cleanupUploads } = require('./helpers/testUtils');

describe('Report routes', () => {
  beforeEach(() => {
    db.__reset();
    cleanupUploads();
  });

  it('generates a consolidated project report', async () => {
    const project = db.__seedProject({ name: 'Harbor Expansion', status: 'active' });
    db.__seedBudget({ project_id: project.id, total_budget: 5000 });
    db.__seedExpense({ project_id: project.id, amount: 1200, category: 'Equipment' });
    db.__seedAttendance({ project_id: project.id, hours_worked: 8 });
    db.__seedAttendance({ project_id: project.id, hours_worked: 7.5 });
    db.__seedMaterial({ project_id: project.id, status: 'ordered', quantity: 10, unit_cost: 50, total_cost: 500 });
    db.__seedMaterial({ project_id: project.id, status: 'used', quantity: 2, unit_cost: 100, total_cost: 200 });
    db.__seedPhoto({ project_id: project.id });

    const response = await request(app)
      .get(`/api/projects/${project.id}/report`)
      .set('Authorization', adminAuthHeader());

    expect(response.status).toBe(200);
    expect(response.body.project.name).toBe('Harbor Expansion');
    expect(response.body.budget_summary).toEqual({ total_budget: 5000, spent_amount: 1200, remaining_amount: 3800 });
    expect(response.body.attendance_summary).toEqual({ total_records: 2, total_hours: 15.5 });
    expect(response.body.materials_summary.total_items).toBe(2);
    expect(response.body.materials_summary.total_cost).toBe(700);
    expect(response.body.photo_count).toBe(1);
  });
});
