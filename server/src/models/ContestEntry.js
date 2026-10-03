'use strict';

const mongoose = require('mongoose');

const contestEntrySchema = new mongoose.Schema(
  {
    contestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Contest',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    score: { type: Number, default: 0, min: 0 },
    correctAnswers: { type: Number, default: 0, min: 0 },
    questionsAttended: { type: Number, default: 0, min: 0 },
    answers: { type: [Number], default: [] },
    playedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

// One play per user per contest (Elite allows a single attempt).
contestEntrySchema.index({ contestId: 1, userId: 1 }, { unique: true });
// Leaderboard ordering.
contestEntrySchema.index({ contestId: 1, score: -1, playedAt: 1 });

module.exports = mongoose.model('ContestEntry', contestEntrySchema);
