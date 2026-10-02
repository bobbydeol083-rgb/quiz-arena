'use strict';

const mongoose = require('mongoose');
const Category = require('../models/Category');
const Question = require('../models/Question');
const { sanitizeQuestions } = require('../utils/serialize');
const { errorBody, asyncHandler } = require('../utils/http');

const MAX_COUNT = 50;

const list = asyncHandler(async (req, res) => {
  const { difficulty } = req.query;
  let { category, count = 10 } = req.query;
  count = Math.max(1, Math.min(MAX_COUNT, parseInt(count, 10) || 10));

  const pipeline = [];
  if (category) {
    let categoryDoc = null;
    if (mongoose.isValidObjectId(category)) {
      categoryDoc = await Category.findById(category);
    } else {
      categoryDoc = await Category.findOne({ name: new RegExp(`^${String(category).trim()}$`, 'i') });
    }
    if (!categoryDoc) {
      return res.status(404).json(errorBody('CATEGORY_NOT_FOUND', 'Category not found'));
    }
    pipeline.push({ $match: { category: categoryDoc._id } });
  }
  if (difficulty) {
    pipeline.push({ $match: { difficulty } });
  }
  pipeline.push({ $sample: { size: count } });

  const questions = await Question.aggregate(pipeline);
  // NEVER leak answerIndex to clients.
  res.json(sanitizeQuestions(questions));
});

module.exports = { list };
