'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/contestController');
const { requireAuth, optionalAuth } = require('../middleware/auth');

const router = Router();

router.get('/', optionalAuth, ctrl.list);
router.post('/', requireAuth, ctrl.create);
router.get('/:id', optionalAuth, ctrl.detail);
router.post('/:id/join', requireAuth, ctrl.join);
router.post('/:id/submit', requireAuth, ctrl.submit);
router.get('/:id/leaderboard', optionalAuth, ctrl.leaderboard);
router.post('/:id/distribute', requireAuth, ctrl.distribute);

module.exports = router;
