'use strict';

const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true, uppercase: true, trim: true, minlength: 6, maxlength: 6 },
    host: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    players: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    mode: { type: String, enum: ['duel', 'room'], default: 'duel' },
    category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null },
    status: { type: String, enum: ['waiting', 'playing', 'finished'], default: 'waiting', index: true },
    questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }],
    // TTL-ish cleanup: rooms are ephemeral, auto-removed 24h after creation.
    createdAt: { type: Date, default: Date.now, expires: 60 * 60 * 24 },
  },
  { timestamps: false }
);

module.exports = mongoose.model('Room', roomSchema);
