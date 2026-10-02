'use strict';

const { Router } = require('express');
const { body, query } = require('express-validator');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/playerController');

const router = Router();

router.post(
  '/location',
  requireAuth,
  [
    body('lng').isFloat({ min: -180, max: 180 }).withMessage('lng must be -180–180').toFloat(),
    body('lat').isFloat({ min: -90, max: 90 }).withMessage('lat must be -90–90').toFloat(),
  ],
  validate,
  ctrl.updateLocation
);

router.get(
  '/nearby',
  requireAuth,
  [
    query('maxDistance').optional().isInt({ min: 1, max: 50000 }).withMessage('maxDistance must be 1–50000 meters').toInt(),
    query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('limit must be 1–50').toInt(),
  ],
  validate,
  ctrl.nearby
);

module.exports = router;
