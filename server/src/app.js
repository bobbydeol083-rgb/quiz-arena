'use strict';

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const { errorBody } = require('./utils/http');
const { notFound, errorHandler } = require('./middleware/errorHandler');

function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors({ origin: env.clientUrl === '*' ? true : env.clientUrl.split(',') }));
  if (!env.isTest) {
    app.use(morgan(env.isProd ? 'combined' : 'dev'));
  }
  app.use(express.json({ limit: '256kb' }));

  app.get('/health', (req, res) => {
    res.json({ ok: true, service: 'quizarena', version: '1.0.0', env: env.nodeEnv });
  });

  // Rate-limit auth endpoints (brute-force protection). Skipped in tests.
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    skip: () => env.isTest,
    handler: (req, res) => res.status(429).json(errorBody('RATE_LIMITED', 'Too many requests, please try again later')),
  });
  app.use('/api/auth', authLimiter);

  app.use('/api/auth', require('./routes/auth'));
  app.use('/api/categories', require('./routes/categories'));
  app.use('/api/questions', require('./routes/questions'));
  app.use('/api/quiz', require('./routes/quiz'));
  app.use('/api/leaderboard', require('./routes/leaderboard'));
  app.use('/api/users', require('./routes/users'));
  app.use('/api/players', require('./routes/players'));
  app.use('/api/rooms', require('./routes/rooms'));
  app.use('/api/packs', require('./routes/packs'));

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = createApp;
