require('dotenv').config({ quiet: true });

const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/auth');
const projectRoutes = require('./routes/projects');
const budgetRoutes = require('./routes/budget');
const attendanceRoutes = require('./routes/attendance');
const materialsRoutes = require('./routes/materials');
const photoRoutes = require('./routes/photos');
const reportRoutes = require('./routes/reports');
const rateLimit = require('express-rate-limit');

const app = express();
const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 400,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later' }
});

app.use(cors());
app.use(express.json());
app.use('/api', apiRateLimiter);
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads')));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api', budgetRoutes);
app.use('/api', attendanceRoutes);
app.use('/api', materialsRoutes);
app.use('/api', photoRoutes);
app.use('/api', reportRoutes);

app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(error.status || 500).json({ message: 'Internal server error' });
});

module.exports = app;
