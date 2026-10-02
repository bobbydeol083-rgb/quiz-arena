'use strict';

const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true, trim: true, maxlength: 40 },
    icon: { type: String, default: '❓', maxlength: 8 },
    color: { type: String, default: '#6C5CE7', match: [/^#[0-9a-fA-F]{6}$/, 'color must be hex like #6C5CE7'] },
    description: { type: String, default: '', maxlength: 200 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Category', categorySchema);
