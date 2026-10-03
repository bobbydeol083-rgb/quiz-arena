'use strict';

const mongoose = require('mongoose');

const prizeSchema = new mongoose.Schema(
  {
    rank: { type: Number, required: true, min: 1 },
    coins: { type: Number, required: true, min: 1 },
  },
  { _id: false }
);

const contestQuestionSchema = new mongoose.Schema(
  {
    question: { type: String, required: true, trim: true },
    options: {
      type: [String],
      required: true,
      validate: (v) => Array.isArray(v) && v.length >= 2,
    },
    answerIndex: { type: Number, required: true, min: 0 },
    explanation: { type: String, default: '' },
  },
  { _id: false }
);

const contestSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 120 },
    description: { type: String, default: '', maxlength: 2000 },
    image: { type: String, default: '' },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    entryFee: { type: Number, default: 0, min: 0 },
    status: {
      type: String,
      enum: ['active', 'inactive'],
      default: 'active',
    },
    prizeDistributed: { type: Boolean, default: false },
    prizes: { type: [prizeSchema], default: [] },
    questions: {
      type: [contestQuestionSchema],
      validate: (v) => Array.isArray(v) && v.length >= 1,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  { timestamps: true }
);

contestSchema.index({ status: 1, startDate: 1, endDate: 1 });

contestSchema.methods.phase = function (now = new Date()) {
  if (this.status !== 'active') return 'inactive';
  if (now < this.startDate) return 'upcoming';
  if (now > this.endDate) return 'ended';
  return 'live';
};

contestSchema.methods.prizePool = function () {
  return (this.prizes || []).reduce((s, p) => s + (p.coins || 0), 0);
};

module.exports = mongoose.model('Contest', contestSchema);
