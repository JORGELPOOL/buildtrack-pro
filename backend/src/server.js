import express from 'express';
import cors from 'cors';
import 'dotenv/config';

import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import resourceRoutes from './routes/resources.js';

if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET must be set.');
}

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Root route
app.get('/', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'buildtrack-pro-api',
    message: 'BuildTrack Pro API is running.',
    health: '/api/health'
  });
});

// API information
app.get('/api', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'buildtrack-pro-api',
    endpoints: {
      health: '/api/health',
      login: '/api/auth/login'
    }
  });
});

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'buildtrack-pro-api'
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api', resourceRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Endpoint not found.' });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error.' });
});

app.listen(process.env.PORT || 3000, () => {
  console.log(`API running on port ${process.env.PORT || 3000}`);
});
