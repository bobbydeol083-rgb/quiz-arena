'use strict';

const mongoose = require('mongoose');
const User = require('../models/User');
const { asyncHandler } = require('../utils/http');

const DEFAULT_MAX_DISTANCE = 5000; // meters
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

// POST /api/players/location { lng, lat }
const updateLocation = asyncHandler(async (req, res) => {
  const { lng, lat } = req.body;
  req.user.location = { type: 'Point', coordinates: [lng, lat] };
  req.user.lastSeen = new Date();
  await req.user.save();
  res.json({ ok: true });
});

// GET /api/players/nearby?maxDistance=5000&limit=20
const nearby = asyncHandler(async (req, res) => {
  const maxDistance = Math.max(1, Math.min(50000, parseInt(req.query.maxDistance, 10) || DEFAULT_MAX_DISTANCE));
  const limit = Math.max(1, Math.min(MAX_LIMIT, parseInt(req.query.limit, 10) || DEFAULT_LIMIT));
  const [lng, lat] = req.user.location?.coordinates || [0, 0];
  const selfId = new mongoose.Types.ObjectId(req.userId);

  const rows = await User.aggregate([
    {
      $geoNear: {
        near: { type: 'Point', coordinates: [lng, lat] },
        distanceField: 'distanceM',
        maxDistance,
        spherical: true,
      },
    },
    { $match: { _id: { $ne: selfId } } },
    { $sort: { distanceM: 1 } },
    { $limit: limit },
    { $project: { username: 1, avatar: 1, xp: 1, level: 1, online: 1, distanceM: 1 } },
  ]);

  res.json(
    rows.map((u) => ({
      id: String(u._id),
      username: u.username,
      avatar: u.avatar,
      xp: u.xp || 0,
      level: u.level || 1,
      online: !!u.online,
      distanceM: Math.round(u.distanceM),
    }))
  );
});

module.exports = { updateLocation, nearby };
