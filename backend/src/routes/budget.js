const express = require('express');

const db = require('../config/db');
const { authenticate, requireAdmin } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

const router = express.Router();
const routeRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 200,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later' }
});

async function ensureProjectExists(projectId) {
  const result = await db.query('SELECT id FROM projects WHERE id = $1', [projectId]);
  return result.rows[0] || null;
}

function toNumber(value) {
  return Number(value || 0);
}

async function getBudgetSummary(projectId) {
  const [budgetResult, spentResult] = await Promise.all([
    db.query('SELECT total_budget FROM budgets WHERE project_id = $1', [projectId]),
    db.query('SELECT COALESCE(SUM(amount), 0) AS spent_amount FROM expenses WHERE project_id = $1', [projectId])
  ]);

  const totalBudget = toNumber(budgetResult.rows[0]?.total_budget);
  const spentAmount = toNumber(spentResult.rows[0]?.spent_amount);

  return {
    total_budget: totalBudget,
    spent_amount: spentAmount,
    remaining_amount: totalBudget - spentAmount
  };
}

function formatExpense(row) {
  return {
    ...row,
    id: Number(row.id),
    project_id: Number(row.project_id),
    created_by: row.created_by === null || row.created_by === undefined ? null : Number(row.created_by),
    amount: Number(row.amount)
  };
}

router.use(routeRateLimiter);
router.use(authenticate);

router.get('/projects/:id/budget', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    return res.json(await getBudgetSummary(req.params.id));
  } catch (error) {
    return next(error);
  }
});

router.post('/projects/:id/budget', requireAdmin, async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const { total_budget } = req.body;

    if (total_budget === undefined || Number.isNaN(Number(total_budget)) || Number(total_budget) < 0) {
      return res.status(400).json({ message: 'A valid total_budget is required' });
    }

    await db.query(
      `INSERT INTO budgets (project_id, total_budget)
       VALUES ($1, $2)
       ON CONFLICT (project_id)
       DO UPDATE SET total_budget = EXCLUDED.total_budget, updated_at = NOW()`,
      [req.params.id, Number(total_budget)]
    );

    return res.json(await getBudgetSummary(req.params.id));
  } catch (error) {
    return next(error);
  }
});

router.get('/projects/:id/expenses', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const result = await db.query(
      `SELECT id, project_id, category, description, amount, date, created_by, created_at
       FROM expenses
       WHERE project_id = $1
       ORDER BY date DESC, id DESC`,
      [req.params.id]
    );

    return res.json(result.rows.map(formatExpense));
  } catch (error) {
    return next(error);
  }
});

router.post('/projects/:id/expenses', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const { category, description = null, amount, date } = req.body;

    if (!category || amount === undefined || !date || Number.isNaN(Number(amount)) || Number(amount) < 0) {
      return res.status(400).json({ message: 'Category, date, and a valid amount are required' });
    }

    const result = await db.query(
      `INSERT INTO expenses (project_id, category, description, amount, date, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, project_id, category, description, amount, date, created_by, created_at`,
      [req.params.id, category, description, Number(amount), date, req.user.id]
    );

    return res.status(201).json(formatExpense(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.put('/expenses/:id', requireAdmin, async (req, res, next) => {
  try {
    const { category, description = null, amount, date } = req.body;

    if (!category || amount === undefined || !date || Number.isNaN(Number(amount)) || Number(amount) < 0) {
      return res.status(400).json({ message: 'Category, date, and a valid amount are required' });
    }

    const result = await db.query(
      `UPDATE expenses
       SET category = $1, description = $2, amount = $3, date = $4
       WHERE id = $5
       RETURNING id, project_id, category, description, amount, date, created_by, created_at`,
      [category, description, Number(amount), date, req.params.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Expense not found' });
    }

    return res.json(formatExpense(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.delete('/expenses/:id', requireAdmin, async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM expenses WHERE id = $1 RETURNING id', [req.params.id]);

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Expense not found' });
    }

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
