'use strict';

const mongoose = require('mongoose');
const User = require('../models/User');
const { errorBody, asyncHandler } = require('../utils/http');
const { tierForLevel } = require('../utils/gamification');

// GET /api/users/:id — public profile
const getById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json(errorBody('INVALID_ID', 'Invalid user id'));
  }
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json(errorBody('USER_NOT_FOUND', 'User not found'));
  }
  res.json({
    user: {
      id: String(user._id),
      username: user.username,
      avatar: user.avatar,
      xp: user.xp,
      level: user.level,
      tier: tierForLevel(user.level),
      coins: user.coins,
      streak: { count: user.streak?.count || 0, lastPlayedAt: user.streak?.lastPlayedAt || null },
      badges: user.badges || [],
      online: !!user.online,
      lastSeen: user.lastSeen,
    },
    stats: {
      played: user.stats?.played || 0,
      won: user.stats?.won || 0,
      correctAnswers: user.stats?.correctAnswers || 0,
      totalAnswers: user.stats?.totalAnswers || 0,
      bestStreak: user.stats?.bestStreak || 0,
    },
  });
});

module.exports = { getById };
