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
const VALID_STATUSES = new Set(['ordered', 'delivered', 'used']);

async function ensureProjectExists(projectId) {
  const result = await db.query('SELECT id FROM projects WHERE id = $1', [projectId]);
  return result.rows[0] || null;
}

function formatMaterial(row) {
  return {
    ...row,
    id: Number(row.id),
    project_id: Number(row.project_id),
    quantity: Number(row.quantity),
    unit_cost: Number(row.unit_cost),
    total_cost: Number(row.total_cost)
  };
}

function validateMaterial(body) {
  if (!body.name || body.quantity === undefined || body.unit_cost === undefined || !body.status) {
    return 'Name, quantity, unit_cost, and status are required';
  }

  if (Number.isNaN(Number(body.quantity)) || Number(body.quantity) < 0 || Number.isNaN(Number(body.unit_cost)) || Number(body.unit_cost) < 0) {
    return 'Quantity and unit_cost must be valid non-negative numbers';
  }

  if (!VALID_STATUSES.has(body.status)) {
    return 'Invalid material status';
  }

  return null;
}

router.use(routeRateLimiter);
router.use(authenticate);

router.get('/projects/:id/materials', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const result = await db.query(
      `SELECT id, project_id, name, quantity, unit, unit_cost, total_cost, supplier, status, date_ordered, date_delivered
       FROM materials
       WHERE project_id = $1
       ORDER BY date_ordered DESC NULLS LAST, id DESC`,
      [req.params.id]
    );

    return res.json(result.rows.map(formatMaterial));
  } catch (error) {
    return next(error);
  }
});

router.post('/projects/:id/materials', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const validationError = validateMaterial(req.body);

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const { name, quantity, unit = null, unit_cost, supplier = null, status, date_ordered = null, date_delivered = null } = req.body;
    const totalCost = Number(quantity) * Number(unit_cost);

    const result = await db.query(
      `INSERT INTO materials (project_id, name, quantity, unit, unit_cost, total_cost, supplier, status, date_ordered, date_delivered)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING id, project_id, name, quantity, unit, unit_cost, total_cost, supplier, status, date_ordered, date_delivered`,
      [req.params.id, name, Number(quantity), unit, Number(unit_cost), totalCost, supplier, status, date_ordered, date_delivered]
    );

    return res.status(201).json(formatMaterial(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.put('/materials/:id', async (req, res, next) => {
  try {
    const validationError = validateMaterial(req.body);

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const { name, quantity, unit = null, unit_cost, supplier = null, status, date_ordered = null, date_delivered = null } = req.body;
    const totalCost = Number(quantity) * Number(unit_cost);

    const result = await db.query(
      `UPDATE materials
       SET name = $1, quantity = $2, unit = $3, unit_cost = $4, total_cost = $5, supplier = $6, status = $7, date_ordered = $8, date_delivered = $9
       WHERE id = $10
       RETURNING id, project_id, name, quantity, unit, unit_cost, total_cost, supplier, status, date_ordered, date_delivered`,
      [name, Number(quantity), unit, Number(unit_cost), totalCost, supplier, status, date_ordered, date_delivered, req.params.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Material not found' });
    }

    return res.json(formatMaterial(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.delete('/materials/:id', requireAdmin, async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM materials WHERE id = $1 RETURNING id', [req.params.id]);

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Material not found' });
    }

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
