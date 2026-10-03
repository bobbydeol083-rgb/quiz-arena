'use strict';

const User = require('../models/User');
const CoinTransaction = require('../models/CoinTransaction');
const { errorBody, asyncHandler } = require('../utils/http');
const { applyCoins } = require('../utils/coins');

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
  await applyCoins(user, awarded, 'Daily scratch reward', 'daily', null);
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

// GET /api/rewards/transactions — server-side coin ledger.
const transactions = asyncHandler(async (req, res) => {
  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
  const txs = await CoinTransaction.find({ userId: req.user.id })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();
  res.json({
    transactions: txs.map((t) => ({
      id: String(t._id),
      amount: t.amount,
      reason: t.reason,
      balanceAfter: t.balanceAfter,
      createdAt: t.createdAt,
    })),
  });
});

module.exports = { claimDaily, referralInfo, transactions, DAILY_TIERS };
