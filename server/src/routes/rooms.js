'use strict';

const { Router } = require('express');
const { body, param } = require('express-validator');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/roomController');

const router = Router();

router.post(
  '/',
  requireAuth,
  [
    body('mode').optional().isIn(['duel', 'room']).withMessage('mode must be duel or room'),
    body('category').optional({ nullable: true }).isMongoId().withMessage('category must be a valid id'),
  ],
  validate,
  ctrl.create
);

router.get(
  '/:code',
  requireAuth,
  [param('code').isString().isLength({ min: 6, max: 6 }).withMessage('code must be 6 characters')],
  validate,
  ctrl.getByCode
);

router.post(
  '/:code/join',
  requireAuth,
  [param('code').isString().isLength({ min: 6, max: 6 }).withMessage('code must be 6 characters')],
  validate,
  ctrl.join
);

module.exports = router;
