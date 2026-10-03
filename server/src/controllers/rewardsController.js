'use strict';

const User = require('../models/User');
const { errorBody, asyncHandler } = require('../utils/http');

// Daily scratch-card reward tiers (coins) with weights.
const DAILY_TIERS = [
  { coins: 10, weight: 40 },
  { coins: 20, weight: 30 },
  { coins: 30, weight: 15 },
  { coins: 50, weight: 10 },
  { coins: 100, weight: 5 },
];

const REFERRER_REWARD = 100;
const REFEREE_REWARD = 50;

function todayKey(d = new Date()) {
  return d.toISOString().slice(0, 10); // yyyy-MM-dd (UTC)
}

function rollDailyTier() {
  const total = DAILY_TIERS.reduce((s, t) => s + t.weight, 0);
  let r = Math.random() * total;
  for (const tier of DAILY_TIERS) {
    r -= tier.weight;
    if (r <= 0) return tier.coins;
  }
  return DAILY_TIERS[0].coins;
}

// POST /api/rewards/daily-claim — server-authoritative daily scratch reward.
const claimDaily = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user.id);
  if (!user) {
    return res.status(404).json(errorBody('USER_NOT_FOUND', 'User not found'));
  }
  const today = todayKey();
  if (user.lastDailyClaim === today) {
    return res.status(409).json(errorBody('ALREADY_CLAIMED', 'Daily reward already claimed today'));
  }
  const awarded = rollDailyTier();
  user.coins += awarded;
  user.lastDailyClaim = today;
  await user.save();
  res.json({ awarded, coins: user.coins, tiers: DAILY_TIERS.map((t) => t.coins) });
});

// GET /api/rewards/referral — my code, count and earnings.
const referralInfo = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user.id).lean();
  if (!user) {
    return res.status(404).json(errorBody('USER_NOT_FOUND', 'User not found'));
  }
  res.json({
    code: user.referralCode || null,
    referredCount: user.referralCount || 0,
    earnedCoins: (user.referralCount || 0) * REFERRER_REWARD,
    referrerReward: REFERRER_REWARD,
    refereeReward: REFEREE_REWARD,
  });
});

module.exports = { claimDaily, referralInfo, DAILY_TIERS };
