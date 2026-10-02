'use strict';

const mongoose = require('mongoose');
const Category = require('../models/Category');
const Question = require('../models/Question');
const GameResult = require('../models/GameResult');
const gamification = require('../utils/gamification');
const { errorBody, asyncHandler } = require('../utils/http');

const MAX_ANSWERS = 50;

// POST /api/quiz/submit
// Server loads the questions, grades them, applies the gamification engine,
// persists a GameResult and updates the user — the client can never self-grade.
const submit = asyncHandler(async (req, res) => {
  const { mode, category, difficulty = 'mixed', answers, startedAt } = req.body;

  const ids = answers.map((a) => a.questionId);
  const questions = await Question.find({ _id: { $in: ids } });
  if (questions.length !== ids.length) {
    return res.status(400).json(errorBody('INVALID_QUESTION', 'One or more questionIds are invalid'));
  }

  let categoryDoc = null;
  if (category) {
    categoryDoc = await Category.findById(category);
    if (!categoryDoc) {
      return res.status(404).json(errorBody('CATEGORY_NOT_FOUND', 'Category not found'));
    }
    const offCategory = questions.some((q) => String(q.category) !== String(categoryDoc._id));
    if (offCategory) {
      return res.status(400).json(errorBody('CATEGORY_MISMATCH', 'Some questions do not belong to the given category'));
    }
  }

  const questionMap = new Map(questions.map((q) => [String(q._id), { answerIndex: q.answerIndex }]));
  const now = new Date();
  const streak = gamification.nextStreak(req.user.streak, now);
  const graded = gamification.gradeSubmission({
    answers,
    questionMap,
    difficulty,
    streakCount: streak.count,
  });

  const rewards = gamification.applyGameResult(req.user, graded, { mode, now });
  const durationMs = Math.max(0, Math.min(Date.now() - Number(startedAt || Date.now()), 24 * 60 * 60 * 1000));

  await GameResult.create({
    user: req.user._id,
    mode,
    category: categoryDoc ? categoryDoc._id : null,
    difficulty,
    score: graded.score,
    correct: graded.correct,
    total: graded.total,
    xpEarned: rewards.xpEarned,
    coinsEarned: rewards.coinsEarned,
    durationMs,
    won: false,
  });
  await req.user.save();

  res.json({
    score: graded.score,
    correct: graded.correct,
    total: graded.total,
    xpEarned: rewards.xpEarned,
    coinsEarned: rewards.coinsEarned,
    newBadges: rewards.newBadges,
    levelUp: rewards.levelUp,
    level: rewards.newLevel,
    tier: rewards.tier,
    streak: rewards.streak,
    avgTimeMs: graded.avgTimeMs,
  });
});

module.exports = { submit, MAX_ANSWERS };
