'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/rewardsController');
const { requireAuth } = require('../middleware/auth');

const router = Router();

router.post('/daily-claim', requireAuth, ctrl.claimDaily);
router.get('/referral', requireAuth, ctrl.referralInfo);
router.get('/transactions', requireAuth, ctrl.transactions);

module.exports = router;
