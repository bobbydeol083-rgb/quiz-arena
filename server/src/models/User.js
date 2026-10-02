'use strict';

const mongoose = require('mongoose');

const streakSchema = new mongoose.Schema(
  {
    count: { type: Number, default: 0, min: 0 },
    lastPlayedAt: { type: Date, default: null },
  },
  { _id: false }
);

const statsSchema = new mongoose.Schema(
  {
    played: { type: Number, default: 0, min: 0 },
    won: { type: Number, default: 0, min: 0 },
    correctAnswers: { type: Number, default: 0, min: 0 },
    totalAnswers: { type: Number, default: 0, min: 0 },
    bestStreak: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      minlength: 3,
      maxlength: 20,
      match: [/^[a-zA-Z0-9_]+$/, 'username may only contain letters, numbers and underscores'],
    },
    email: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'email must be valid'],
    },
    passwordHash: { type: String, required: true, select: false },
    avatar: { type: String, default: '🦊', maxlength: 8 },
    xp: { type: Number, default: 0, min: 0 },
    level: { type: Number, default: 1, min: 1, max: 8 },
    coins: { type: Number, default: 0, min: 0 },
    streak: { type: streakSchema, default: () => ({}) },
    badges: { type: [String], default: [] },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
    },
    online: { type: Boolean, default: false },
    lastSeen: { type: Date, default: Date.now },
    stats: { type: statsSchema, default: () => ({}) },
    // SHA-256 hashes of active refresh-token jtis (never raw tokens).
    refreshTokens: { type: [String], default: [], select: false },
  },
  { timestamps: true }
);

userSchema.index({ location: '2dsphere' });
userSchema.index({ xp: -1 });
userSchema.index({ online: 1 });

module.exports = mongoose.model('User', userSchema);
