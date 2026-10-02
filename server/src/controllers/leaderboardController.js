'use strict';

const mongoose = require('mongoose');
const User = require('../models/User');
const GameResult = require('../models/GameResult');
const { publicUser } = require('../utils/serialize');
const { asyncHandler } = require('../utils/http');

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

function shape(entry, rank) {
  return {
    rank,
    user: { id: String(entry.user._id), username: entry.user.username, avatar: entry.user.avatar },
    points: entry.points,
  };
}

// GET /api/leaderboard?scope=weekly|alltime&limit=50
const get = asyncHandler(async (req, res) => {
  const scope = req.query.scope === 'alltime' ? 'alltime' : 'weekly';
  const limit = Math.max(1, Math.min(MAX_LIMIT, parseInt(req.query.limit, 10) || DEFAULT_LIMIT));
  const meId = req.userId ? new mongoose.Types.ObjectId(req.userId) : null;

  let entries;
  let me;

  if (scope === 'weekly') {
    const since = new Date(Date.now() - WEEK_MS);
    const rows = await GameResult.aggregate([
      { $match: { createdAt: { $gte: since } } },
      { $group: { _id: '$user', points: { $sum: '$xpEarned' } } },
      { $sort: { points: -1 } },
      { $limit: limit },
      { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } },
      { $unwind: '$user' },
    ]);
    entries = rows.map((r, i) => shape({ user: r.user, points: r.points }, i + 1));

    let myPoints = 0;
    let myRank = null;
    if (meId) {
      const mine = await GameResult.aggregate([
        { $match: { user: meId, createdAt: { $gte: since } } },
        { $group: { _id: null, points: { $sum: '$xpEarned' } } },
      ]);
      myPoints = mine[0]?.points || 0;
      if (myPoints > 0) {
        const better = await GameResult.aggregate([
          { $match: { createdAt: { $gte: since } } },
          { $group: { _id: '$user', points: { $sum: '$xpEarned' } } },
          { $match: { points: { $gt: myPoints } } },
          { $count: 'n' },
        ]);
        myRank = (better[0]?.n || 0) + 1;
      }
    }
    me = { rank: myRank, points: myPoints };
  } else {
    const users = await User.find().sort({ xp: -1 }).limit(limit).lean();
    entries = users.map((u, i) => shape({ user: u, points: u.xp || 0 }, i + 1));

    let myRank = null;
    let myPoints = 0;
    if (meId) {
      const meUser = await User.findById(meId).lean();
      myPoints = meUser?.xp || 0;
      myRank = (await User.countDocuments({ xp: { $gt: myPoints } })) + 1;
    }
    me = { rank: myRank, points: myPoints };
  }

  res.json({ scope, entries, me });
});

module.exports = { get };
