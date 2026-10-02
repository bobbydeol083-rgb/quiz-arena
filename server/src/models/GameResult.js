'use strict';

const mongoose = require('mongoose');

const MODES = ['solo', 'blitz', 'marathon', 'daily', 'duel', 'room'];

const gameResultSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    mode: { type: String, enum: MODES, required: true },
    category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard', 'mixed'], default: 'mixed' },
    score: { type: Number, required: true, min: 0 },
    correct: { type: Number, required: true, min: 0 },
    total: { type: Number, required: true, min: 1 },
    xpEarned: { type: Number, required: true, min: 0 },
    coinsEarned: { type: Number, required: true, min: 0 },
    durationMs: { type: Number, default: 0, min: 0 },
    won: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now, index: true }, // indexed for weekly leaderboards
  },
  { timestamps: false }
);

gameResultSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('GameResult', gameResultSchema);
module.exports.MODES = MODES;
