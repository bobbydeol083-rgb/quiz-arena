'use strict';

const mongoose = require('mongoose');

const PACK_MODES = ['quiz', 'bluff'];
const PACK_STATUS = ['draft', 'published'];

/**
 * GamePack — a user-publishable custom game.
 *
 * Lets players author their own question packs (e.g. "Desi Pop Culture",
 * "Fake Facts") and publish them for the whole community to install and
 * play. A pack carries its own questions plus the game mode it is built
 * for ('quiz' = classic 4-option rounds, 'bluff' = Bluff & Brain rounds
 * where players invent fake answers).
 */
const packQuestionSchema = new mongoose.Schema(
  {
    question: { type: String, required: true, trim: true, maxlength: 500 },
    options: {
      type: [String],
      required: true,
      validate: {
        validator: (v) => Array.isArray(v) && v.length === 4 && v.every((o) => typeof o === 'string' && o.trim().length > 0),
        message: 'options must be an array of exactly 4 non-empty strings',
      },
    },
    answerIndex: { type: Number, required: true, min: 0, max: 3 },
    explanation: { type: String, default: '', maxlength: 500 },
  },
  { _id: false }
);

const gamePackSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, minlength: 3, maxlength: 80 },
    slug: { type: String, required: true, unique: true, index: true, lowercase: true, trim: true },
    description: { type: String, default: '', trim: true, maxlength: 500 },
    label: { type: String, default: 'Custom', trim: true, maxlength: 40 },
    mode: { type: String, enum: PACK_MODES, default: 'quiz', index: true },
    questions: {
      type: [packQuestionSchema],
      required: true,
      validate: {
        validator: (v) => Array.isArray(v) && v.length >= 5 && v.length <= 50,
        message: 'a pack needs 5–50 questions',
      },
    },
    version: { type: Number, default: 1, min: 1 },
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status: { type: String, enum: PACK_STATUS, default: 'draft', index: true },
    installs: { type: Number, default: 0, min: 0 },
    plays: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

gamePackSchema.index({ status: 1, installs: -1 });
gamePackSchema.index({ status: 1, createdAt: -1 });
gamePackSchema.index({ title: 'text', description: 'text', label: 'text' });

/** Public card shape for browse lists — never leaks per-question answers. */
gamePackSchema.methods.toCard = function () {
  return {
    id: String(this._id),
    title: this.title,
    slug: this.slug,
    description: this.description,
    label: this.label,
    mode: this.mode,
    questionCount: this.questions.length,
    version: this.version,
    author: this.author && this.author.username ? { id: String(this.author._id), username: this.author.username } : undefined,
    installs: this.installs,
    plays: this.plays,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('GamePack', gamePackSchema);
module.exports.PACK_MODES = PACK_MODES;
module.exports.PACK_STATUS = PACK_STATUS;
