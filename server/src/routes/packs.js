'use strict';

const { Router } = require('express');
const { body, query, param } = require('express-validator');
const validate = require('../middleware/validate');
const { requireAuth, optionalAuth } = require('../middleware/auth');
const ctrl = require('../controllers/packController');

const router = Router();

const idParam = [param('id').isMongoId().withMessage('id must be a valid pack id')];

router.get(
  '/',
  [
    query('search').optional().isString().withMessage('search must be a string'),
    query('mode').optional().isIn(['quiz', 'bluff']).withMessage('mode must be quiz or bluff'),
    query('sort').optional().isIn(['popular', 'newest']).withMessage('sort must be popular or newest'),
    query('page').optional().isInt({ min: 1 }).withMessage('page must be >= 1').toInt(),
    query('limit').optional().isInt({ min: 1, max: 30 }).withMessage('limit must be 1–30').toInt(),
  ],
  validate,
  ctrl.list
);

// NOTE: /mine must be registered before /:id so "mine" isn't parsed as an id.
router.get('/mine', requireAuth, ctrl.mine);

router.get('/:id', idParam, validate, optionalAuth, ctrl.get);

router.post(
  '/',
  requireAuth,
  [
    body('title').isString().withMessage('title must be a string'),
    body('description').optional().isString().withMessage('description must be a string'),
    body('label').optional().isString().withMessage('label must be a string'),
    body('mode').optional().isString().withMessage('mode must be a string'),
    body('questions').isArray().withMessage('questions must be an array'),
  ],
  validate,
  ctrl.create
);

router.put(
  '/:id',
  requireAuth,
  [...idParam, body('title').optional().isString(), body('description').optional().isString(), body('label').optional().isString(), body('mode').optional().isString(), body('questions').optional().isArray()],
  validate,
  ctrl.update
);

router.post('/:id/publish', requireAuth, idParam, validate, ctrl.publish);
router.post('/:id/unpublish', requireAuth, idParam, validate, ctrl.unpublish);
router.delete('/:id', requireAuth, idParam, validate, ctrl.remove);
router.post('/:id/install', requireAuth, idParam, validate, ctrl.install);
router.post('/:id/played', requireAuth, idParam, validate, ctrl.played);

module.exports = router;
