'use strict';

const Category = require('../models/Category');
const Question = require('../models/Question');
const { asyncHandler } = require('../utils/http');

const list = asyncHandler(async (req, res) => {
  const categories = await Category.find().sort({ name: 1 }).lean();
  const counts = await Question.aggregate([
    { $group: { _id: '$category', count: { $sum: 1 } } },
  ]);
  const countById = new Map(counts.map((c) => [String(c._id), c.count]));
  res.json(
    categories.map((c) => ({
      id: String(c._id),
      name: c.name,
      icon: c.icon,
      color: c.color,
      description: c.description,
      quizCount: countById.get(String(c._id)) || 0,
    }))
  );
});

module.exports = { list };
