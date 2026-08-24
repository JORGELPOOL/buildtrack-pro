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
const VALID_STATUSES = new Set(['planning', 'active', 'completed', 'on_hold']);

function formatProject(row) {
  if (!row) {
    return null;
  }

  return {
    ...row,
    id: Number(row.id)
  };
}

function validateProjectPayload(body) {
  const { name, status } = body;

  if (!name || !status) {
    return 'Name and status are required';
  }

  if (!VALID_STATUSES.has(status)) {
    return 'Invalid project status';
  }

  return null;
}

router.use(routeRateLimiter);
router.use(authenticate);

router.get('/', async (req, res, next) => {
  try {
    const result = await db.query(
      'SELECT id, name, description, client_name, start_date, end_date, status, created_at FROM projects ORDER BY created_at DESC, id DESC'
    );

    return res.json(result.rows.map(formatProject));
  } catch (error) {
    return next(error);
  }
});

router.post('/', requireAdmin, async (req, res, next) => {
  try {
    const validationError = validateProjectPayload(req.body);

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const { name, description = null, client_name = null, start_date = null, end_date = null, status } = req.body;
    const result = await db.query(
      `INSERT INTO projects (name, description, client_name, start_date, end_date, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, name, description, client_name, start_date, end_date, status, created_at`,
      [name, description, client_name, start_date, end_date, status]
    );

    return res.status(201).json(formatProject(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const result = await db.query(
      'SELECT id, name, description, client_name, start_date, end_date, status, created_at FROM projects WHERE id = $1',
      [req.params.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Project not found' });
    }

    return res.json(formatProject(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.put('/:id', requireAdmin, async (req, res, next) => {
  try {
    const validationError = validateProjectPayload(req.body);

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const { name, description = null, client_name = null, start_date = null, end_date = null, status } = req.body;
    const result = await db.query(
      `UPDATE projects
       SET name = $1, description = $2, client_name = $3, start_date = $4, end_date = $5, status = $6
       WHERE id = $7
       RETURNING id, name, description, client_name, start_date, end_date, status, created_at`,
      [name, description, client_name, start_date, end_date, status, req.params.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Project not found' });
    }

    return res.json(formatProject(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.delete('/:id', requireAdmin, async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM projects WHERE id = $1 RETURNING id', [req.params.id]);

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Project not found' });
    }

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
