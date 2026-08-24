const express = require('express');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

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
const uploadDirectory = path.resolve(__dirname, '../../uploads');

fs.mkdirSync(uploadDirectory, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDirectory),
  filename: (_req, file, cb) => {
    const extension = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${extension}`);
  }
});

const upload = multer({ storage });

async function ensureProjectExists(projectId) {
  const result = await db.query('SELECT id FROM projects WHERE id = $1', [projectId]);
  return result.rows[0] || null;
}

function formatPhoto(row) {
  return {
    ...row,
    id: Number(row.id),
    project_id: Number(row.project_id),
    uploaded_by: Number(row.uploaded_by)
  };
}

function buildUploadPath(filename) {
  const safeFilename = path.basename(filename);
  const resolvedPath = path.resolve(uploadDirectory, safeFilename);

  if (!resolvedPath.startsWith(uploadDirectory + path.sep) && resolvedPath !== path.join(uploadDirectory, safeFilename)) {
    throw new Error('Invalid upload path');
  }

  return resolvedPath;
}

function removeUploadedFile(filename) {
  const filePath = buildUploadPath(filename);
  fs.unlink(filePath, (error) => {
    if (error && error.code !== 'ENOENT') {
      console.error(error);
    }
  });
}

router.use(routeRateLimiter);
router.use(authenticate);

router.get('/projects/:id/photos', async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }

    const result = await db.query(
      `SELECT id, project_id, filename, original_name, caption, uploaded_by, created_at
       FROM photos
       WHERE project_id = $1
       ORDER BY created_at DESC, id DESC`,
      [req.params.id]
    );

    return res.json(result.rows.map(formatPhoto));
  } catch (error) {
    return next(error);
  }
});

router.post('/projects/:id/photos', upload.single('photo'), async (req, res, next) => {
  try {
    const project = await ensureProjectExists(req.params.id);

    if (!project) {
      if (req.file?.filename) {
        removeUploadedFile(req.file.filename);
      }
      return res.status(404).json({ message: 'Project not found' });
    }

    if (!req.file) {
      return res.status(400).json({ message: 'A photo file is required' });
    }

    const result = await db.query(
      `INSERT INTO photos (project_id, filename, original_name, caption, uploaded_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, project_id, filename, original_name, caption, uploaded_by, created_at`,
      [req.params.id, req.file.filename, req.file.originalname, req.body.caption || null, req.user.id]
    );

    return res.status(201).json(formatPhoto(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

router.delete('/photos/:id', requireAdmin, async (req, res, next) => {
  try {
    const result = await db.query(
      'DELETE FROM photos WHERE id = $1 RETURNING id, project_id, filename, original_name, caption, uploaded_by, created_at',
      [req.params.id]
    );

    const photo = result.rows[0];

    if (!photo) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    removeUploadedFile(photo.filename);

    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
