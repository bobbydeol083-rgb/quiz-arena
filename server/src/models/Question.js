'use strict';

const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema(
  {
    category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true, index: true },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], required: true, index: true },
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
  { timestamps: true }
);

questionSchema.index({ category: 1, difficulty: 1 });

module.exports = mongoose.model('Question', questionSchema);
