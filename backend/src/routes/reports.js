const express = require('express');

const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

const router = express.Router();
const routeRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 200,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later' }
});

function toNumber(value) {
  return Number(value || 0);
}

router.use(routeRateLimiter);
router.use(authenticate);

router.get('/projects/:id/report', async (req, res, next) => {
  try {
    const projectResult = await db.query(
      'SELECT id, name, description, client_name, start_date, end_date, status, created_at FROM projects WHERE id = $1',
      [req.params.id]
    );

    const project = projectResult.rows[0];

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const [budgetResult, spentResult, attendanceSummary, materialsSummary, materialStatuses, photoCount] = await Promise.all([
      db.query('SELECT total_budget FROM budgets WHERE project_id = $1', [req.params.id]),
      db.query('SELECT COALESCE(SUM(amount), 0) AS spent_amount FROM expenses WHERE project_id = $1', [req.params.id]),
      db.query('SELECT COUNT(*)::int AS total_records, COALESCE(SUM(hours_worked), 0) AS total_hours FROM attendance WHERE project_id = $1', [req.params.id]),
      db.query('SELECT COUNT(*)::int AS total_items, COALESCE(SUM(total_cost), 0) AS total_cost FROM materials WHERE project_id = $1', [req.params.id]),
      db.query('SELECT status, COUNT(*)::int AS count FROM materials WHERE project_id = $1 GROUP BY status ORDER BY status', [req.params.id]),
      db.query('SELECT COUNT(*)::int AS photo_count FROM photos WHERE project_id = $1', [req.params.id])
    ]);

    const totalBudget = toNumber(budgetResult.rows[0]?.total_budget);
    const spentAmount = toNumber(spentResult.rows[0]?.spent_amount);

    return res.json({
      project: {
        ...project,
        id: Number(project.id)
      },
      budget_summary: {
        total_budget: totalBudget,
        spent_amount: spentAmount,
        remaining_amount: totalBudget - spentAmount
      },
      attendance_summary: {
        total_records: Number(attendanceSummary.rows[0]?.total_records || 0),
        total_hours: toNumber(attendanceSummary.rows[0]?.total_hours)
      },
      materials_summary: {
        total_items: Number(materialsSummary.rows[0]?.total_items || 0),
        total_cost: toNumber(materialsSummary.rows[0]?.total_cost),
        by_status: materialStatuses.rows.map((row) => ({
          status: row.status,
          count: Number(row.count)
        }))
      },
      photo_count: Number(photoCount.rows[0]?.photo_count || 0)
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
