'use strict';

const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const { MODES } = require('../models/GameResult');
const ctrl = require('../controllers/quizController');

const router = Router();

router.post(
  '/submit',
  requireAuth,
  [
    body('mode').isString().isIn(MODES).withMessage(`mode must be one of: ${MODES.join(', ')}`),
    body('category').optional({ nullable: true }).isMongoId().withMessage('category must be a valid id'),
    body('difficulty').optional().isIn(['easy', 'medium', 'hard', 'mixed']).withMessage('difficulty must be easy, medium, hard or mixed'),
    body('answers').isArray({ min: 1, max: ctrl.MAX_ANSWERS }).withMessage(`answers must be an array of 1–${ctrl.MAX_ANSWERS}`),
    body('answers.*.questionId').isMongoId().withMessage('answers[].questionId must be a valid id'),
    // -1 = the client timed out / skipped: counts as answered, never correct.
    body('answers.*.selectedIndex').isInt({ min: -1, max: 3 }).withMessage('answers[].selectedIndex must be -1–3 (-1 = timed out)').toInt(),
    body('answers.*.timeMs').optional().isInt({ min: 0, max: 600000 }).withMessage('answers[].timeMs must be 0–600000').toInt(),
    // Accept epoch-ms (int) or an ISO-8601 string; normalize to epoch-ms.
    body('startedAt').optional().custom((v) => {
      const t = typeof v === 'number' ? v : Date.parse(v);
      return Number.isFinite(t) && t >= 0;
    }).withMessage('startedAt must be epoch-ms or an ISO-8601 string').customSanitizer((v) => (
      typeof v === 'number' ? Math.floor(v) : Date.parse(v)
    )),
  ],
  validate,
  ctrl.submit
);

module.exports = router;
