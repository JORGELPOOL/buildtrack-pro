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

function calculateHours(checkIn, checkOut) {
  if (!checkIn || !checkOut) {
    return null;
  }

  const [inHour, inMinute] = checkIn.split(':').map(Number);
  const [outHour, outMinute] = checkOut.split(':').map(Number);
  const totalMinutes = (outHour * 60 + outMinute) - (inHour * 60 + inMinute);

  return Number((totalMinutes / 60).toFixed(2));
}

function formatAttendance(row) {
  return {
    ...row,
    id: Number(row.id),
    project_id: Number(row.project_id),
    hours_worked: row.hours_worked === null || row.hours_worked === undefined ? null : Number(row.hours_worked)
  };
}

router.use(routeRateLimiter);
router.use(authenticate);

router.get('/projects/:id/attendance', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const result = await db.query(
      `SELECT id, project_id, worker_name, date, check_in, check_out, hours_worked, notes
       FROM attendance
       WHERE project_id = $1
       ORDER BY date DESC, id DESC`,
      [req.params.id]
    );

    return res.json(result.rows.map(formatAttendance));
  } catch (error) {
    return next(error);
  }
});

router.post('/projects/:id/attendance', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const { worker_name, date, check_in = null, check_out = null, hours_worked, notes = null } = req.body;

    if (!worker_name || !date) {
      return res.status(400).json({ message: 'Worker name and date are required' });
    }

    const computedHours = hours_worked !== undefined && hours_worked !== null
      ? Number(hours_worked)
      : calculateHours(check_in, check_out);

    if (computedHours !== null && (Number.isNaN(computedHours) || computedHours < 0)) {
      return res.status(400).json({ message: 'hours_worked must be a valid non-negative number' });
    }

    const result = await db.query(
      `INSERT INTO attendance (project_id, worker_name, date, check_in, check_out, hours_worked, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, project_id, worker_name, date, check_in, check_out, hours_worked, notes`,
      [req.params.id, worker_name, date, check_in, check_out, computedHours, notes]
    );

    return res.status(201).json(formatAttendance(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.put('/attendance/:id', async (req, res, next) => {
  try {
    const { worker_name, date, check_in = null, check_out = null, hours_worked, notes = null } = req.body;

    if (!worker_name || !date) {
      return res.status(400).json({ message: 'Worker name and date are required' });
    }

    const computedHours = hours_worked !== undefined && hours_worked !== null
      ? Number(hours_worked)
      : calculateHours(check_in, check_out);

    if (computedHours !== null && (Number.isNaN(computedHours) || computedHours < 0)) {
      return res.status(400).json({ message: 'hours_worked must be a valid non-negative number' });
    }

    const result = await db.query(
      `UPDATE attendance
       SET worker_name = $1, date = $2, check_in = $3, check_out = $4, hours_worked = $5, notes = $6
       WHERE id = $7
       RETURNING id, project_id, worker_name, date, check_in, check_out, hours_worked, notes`,
      [worker_name, date, check_in, check_out, computedHours, notes, req.params.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Attendance record not found' });
    }

    return res.json(formatAttendance(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.delete('/attendance/:id', requireAdmin, async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM attendance WHERE id = $1 RETURNING id', [req.params.id]);

    if (!result.rows[0]) {
      return res.status(404).json({ message: 'Attendance record not found' });
    }

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
