'use strict';

const { Router } = require('express');
const { query } = require('express-validator');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/leaderboardController');

const router = Router();

// Optional auth: leaderboard is public, but `me` needs a token.
router.get(
  '/',
  [
    query('scope').optional().isIn(['weekly', 'alltime']).withMessage('scope must be weekly or alltime'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be 1–100').toInt(),
  ],
  validate,
  (req, res, next) => {
    const header = req.headers.authorization || '';
    if (header.startsWith('Bearer ')) return requireAuth(req, res, next);
    next();
  },
  ctrl.get
);

module.exports = router;
