'use strict';

const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const ctrl = require('../controllers/authController');

const router = Router();

const passwordRule = body('password')
  .isString().withMessage('password must be a string')
  .isLength({ min: 8, max: 72 }).withMessage('password must be 8–72 characters');

router.post(
  '/register',
  [
    body('username').trim().isLength({ min: 3, max: 20 }).withMessage('username must be 3–20 characters')
      .matches(/^[a-zA-Z0-9_]+$/).withMessage('username may only contain letters, numbers and underscores'),
    body('email').trim().isEmail().withMessage('email must be valid').normalizeEmail(),
    passwordRule,
  ],
  validate,
  ctrl.register
);

router.post(
  '/login',
  [
    body('email').trim().isEmail().withMessage('email must be valid').normalizeEmail(),
    body('password').isString().withMessage('password must be a string').notEmpty().withMessage('password is required'),
  ],
  validate,
  ctrl.login
);

router.post(
  '/refresh',
  [body('refreshToken').isString().withMessage('refreshToken must be a string').notEmpty().withMessage('refreshToken is required')],
  validate,
  ctrl.refresh
);

router.post('/logout', requireAuth, ctrl.logout);
router.get('/me', requireAuth, ctrl.me);

module.exports = router;
