'use strict';

const mongoose = require('mongoose');
const Contest = require('../models/Contest');
const ContestEntry = require('../models/ContestEntry');
const User = require('../models/User');
const { errorBody, asyncHandler } = require('../utils/http');
const { applyCoins } = require('../utils/coins');

function sanitizeQuestions(contest) {
  return (contest.questions || []).map((q, i) => ({
    index: i,
    question: q.question,
    options: q.options,
    explanation: undefined,
  }));
}

function contestCard(c, playedIds) {
  return {
    id: String(c._id),
    name: c.name,
    description: c.description,
    image: c.image,
    startDate: c.startDate,
    endDate: c.endDate,
    entryFee: c.entryFee,
    phase: c.phase(),
    prizePool: c.prizePool(),
    prizeCount: (c.prizes || []).length,
    questionCount: (c.questions || []).length,
    played: playedIds.has(String(c._id)),
  };
}

// GET /api/contests — live first, then upcoming, then ended.
const list = asyncHandler(async (req, res) => {
  const contests = await Contest.find({ status: 'active' })
    .sort({ startDate: 1 })
    .lean();
  let playedIds = new Set();
  if (req.user) {
    const entries = await ContestEntry.find({ userId: req.user.id })
      .select('contestId')
      .lean();
    playedIds = new Set(entries.map((e) => String(e.contestId)));
  }

  const counts = await ContestEntry.aggregate([
    { $group: { _id: '$contestId', n: { $sum: 1 } } },
  ]);
  const countBy = new Map(counts.map((c) => [String(c._id), c.n]));

  const cards = contests.map((c) => {
    const doc = new Contest(c);
    return {
      ...contestCard(doc, playedIds),
      participants: countBy.get(String(c._id)) || 0,
    };
  });

  const order = { live: 0, upcoming: 1, ended: 2, inactive: 3 };
  cards.sort((a, b) => (order[a.phase] ?? 3) - (order[b.phase] ?? 3));

  res.json({ contests: cards });
});

// POST /api/contests — create a contest.
const create = asyncHandler(async (req, res) => {
  const {
    name,
    description = '',
    image = '',
    startDate,
    endDate,
    entryFee = 0,
    prizes = [],
    questions,
  } = req.body || {};

  if (!name || !startDate || !endDate) {
    return res
      .status(400)
      .json(errorBody('INVALID_CONTEST', 'name, startDate and endDate are required'));
  }
  if (new Date(startDate) >= new Date(endDate)) {
    return res
      .status(400)
      .json(errorBody('INVALID_DATES', 'endDate must be after startDate'));
  }
  if (!Array.isArray(questions) || questions.length === 0) {
    return res
      .status(400)
      .json(errorBody('INVALID_QUESTIONS', 'At least one question is required'));
  }
  for (const q of questions) {
    if (
      !q.question ||
      !Array.isArray(q.options) ||
      q.options.length < 2 ||
      typeof q.answerIndex !== 'number' ||
      q.answerIndex < 0 ||
      q.answerIndex >= q.options.length
    ) {
      return res
        .status(400)
        .json(errorBody('INVALID_QUESTIONS', 'Each question needs text, 2+ options and a valid answerIndex'));
    }
  }
  const cleanPrizes = (Array.isArray(prizes) ? prizes : [])
    .filter((p) => p && p.rank > 0 && p.coins > 0)
    .map((p) => ({ rank: p.rank, coins: p.coins }))
    .sort((a, b) => a.rank - b.rank);

  const contest = await Contest.create({
    name: String(name).slice(0, 120),
    description: String(description).slice(0, 2000),
    image: String(image).slice(0, 500),
    startDate: new Date(startDate),
    endDate: new Date(endDate),
    entryFee: Math.max(0, Number(entryFee) || 0),
    prizes: cleanPrizes,
    questions: questions.map((q) => ({
      question: String(q.question),
      options: q.options.map((o) => String(o)),
      answerIndex: q.answerIndex,
      explanation: String(q.explanation || ''),
    })),
    createdBy: req.user ? req.user.id : null,
  });

  res.status(201).json({ id: String(contest._id) });
});

// GET /api/contests/:id — detail + prizes + my entry + top leaderboard.
const detail = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json(errorBody('INVALID_ID', 'Invalid contest id'));
  }
  const contest = await Contest.findById(id);
  if (!contest) {
    return res.status(404).json(errorBody('CONTEST_NOT_FOUND', 'Contest not found'));
  }
  let myEntry = null;
  if (req.user) {
    myEntry = await ContestEntry.findOne({
      contestId: contest._id,
      userId: req.user.id,
    }).lean();
  }
  const top = await ContestEntry.find({ contestId: contest._id })
    .sort({ score: -1, playedAt: 1 })
    .limit(10)
    .populate('userId', 'username avatar')
    .lean();

  res.json({
    id: String(contest._id),
    name: contest.name,
    description: contest.description,
    image: contest.image,
    startDate: contest.startDate,
    endDate: contest.endDate,
    entryFee: contest.entryFee,
    phase: contest.phase(),
    prizePool: contest.prizePool(),
    prizes: contest.prizes,
    questionCount: contest.questions.length,
    prizeDistributed: contest.prizeDistributed,
    myEntry: myEntry
      ? {
          score: myEntry.score,
          correctAnswers: myEntry.correctAnswers,
          questionsAttended: myEntry.questionsAttended,
          submitted: myEntry.answers.length > 0,
        }
      : null,
    top: top.map((e, i) => ({
      rank: i + 1,
      username: e.userId?.username || '?',
      avatar: e.userId?.avatar || '🦊',
      score: e.score,
      correctAnswers: e.correctAnswers,
    })),
  });
});

// POST /api/contests/:id/join — pay the entry fee, receive questions.
const join = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json(errorBody('INVALID_ID', 'Invalid contest id'));
  }
  const contest = await Contest.findById(id);
  if (!contest) {
    return res.status(404).json(errorBody('CONTEST_NOT_FOUND', 'Contest not found'));
  }
  if (contest.phase() !== 'live') {
    return res
      .status(409)
      .json(errorBody('CONTEST_NOT_LIVE', 'This contest is not live right now'));
  }
  const existing = await ContestEntry.findOne({
    contestId: contest._id,
    userId: req.user.id,
  });
  if (existing) {
    return res
      .status(409)
      .json(errorBody('ALREADY_JOINED', 'You have already joined this contest'));
  }

  const user = await User.findById(req.user.id);
  if (!user) {
    return res.status(404).json(errorBody('USER_NOT_FOUND', 'User not found'));
  }
  if (contest.entryFee > 0) {
    try {
      await applyCoins(
        user,
        -contest.entryFee,
        `Contest entry: ${contest.name}`,
        'contest',
        contest._id
      );
    } catch (e) {
      if (e.code === 'INSUFFICIENT_COINS') {
        return res
          .status(402)
          .json(errorBody('INSUFFICIENT_COINS', 'Not enough coins for the entry fee'));
      }
      throw e;
    }
    await user.save();
  }

  await ContestEntry.create({
    contestId: contest._id,
    userId: user._id,
    score: 0,
    correctAnswers: 0,
    questionsAttended: 0,
    answers: [],
  });

  res.json({ questions: sanitizeQuestions(contest), coins: user.coins });
});

// POST /api/contests/:id/submit — server-side grading, one attempt.
const submit = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json(errorBody('INVALID_ID', 'Invalid contest id'));
  }
  const contest = await Contest.findById(id);
  if (!contest) {
    return res.status(404).json(errorBody('CONTEST_NOT_FOUND', 'Contest not found'));
  }
  const entry = await ContestEntry.findOne({
    contestId: contest._id,
    userId: req.user.id,
  });
  if (!entry) {
    return res
      .status(409)
      .json(errorBody('NOT_JOINED', 'Join the contest before submitting'));
  }
  if (entry.answers.length > 0) {
    return res
      .status(409)
      .json(errorBody('ALREADY_SUBMITTED', 'You have already submitted'));
  }
  if (contest.phase() === 'upcoming') {
    return res
      .status(409)
      .json(errorBody('CONTEST_NOT_LIVE', 'This contest has not started yet'));
  }

  const answers = Array.isArray(req.body?.answers) ? req.body.answers : [];
  const questions = contest.questions || [];
  let correct = 0;
  const graded = questions.map((q, i) => {
    const a = typeof answers[i] === 'number' ? answers[i] : -1;
    const ok = a === q.answerIndex;
    if (ok) correct++;
    return a;
  });

  entry.answers = graded;
  entry.correctAnswers = correct;
  entry.questionsAttended = graded.filter((a) => a >= 0).length;
  entry.score = correct * 10;
  await entry.save();

  // Rank among all submitted entries.
  const better = await ContestEntry.countDocuments({
    contestId: contest._id,
    $or: [
      { score: { $gt: entry.score } },
      { score: entry.score, playedAt: { $lt: entry.playedAt } },
    ],
  });

  res.json({
    score: entry.score,
    correctAnswers: correct,
    total: questions.length,
    rank: better + 1,
  });
});

// GET /api/contests/:id/leaderboard
const leaderboard = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json(errorBody('INVALID_ID', 'Invalid contest id'));
  }
  const contest = await Contest.findById(id).select('_id');
  if (!contest) {
    return res.status(404).json(errorBody('CONTEST_NOT_FOUND', 'Contest not found'));
  }
  const entries = await ContestEntry.find({
    contestId: contest._id,
    answers: { $ne: [] },
  })
    .sort({ score: -1, playedAt: 1 })
    .limit(100)
    .populate('userId', 'username avatar')
    .lean();

  res.json({
    leaderboard: entries.map((e, i) => ({
      rank: i + 1,
      username: e.userId?.username || '?',
      avatar: e.userId?.avatar || '🦊',
      score: e.score,
      correctAnswers: e.correctAnswers,
    })),
  });
});

// POST /api/contests/:id/distribute — award prizes to top ranks (idempotent).
const distribute = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) {
    return res.status(400).json(errorBody('INVALID_ID', 'Invalid contest id'));
  }
  const contest = await Contest.findById(id);
  if (!contest) {
    return res.status(404).json(errorBody('CONTEST_NOT_FOUND', 'Contest not found'));
  }
  if (contest.phase() !== 'ended') {
    return res
      .status(409)
      .json(errorBody('CONTEST_NOT_ENDED', 'Prizes can only be distributed after the contest ends'));
  }
  if (contest.prizeDistributed) {
    return res
      .status(409)
      .json(errorBody('ALREADY_DISTRIBUTED', 'Prizes were already distributed'));
  }
  // Only the creator (or anyone, when created without owner — dev fallback)
  // may distribute.
  if (
    contest.createdBy &&
    String(contest.createdBy) !== String(req.user.id)
  ) {
    return res
      .status(403)
      .json(errorBody('FORBIDDEN', 'Only the contest creator can distribute prizes'));
  }

  const ranked = await ContestEntry.find({
    contestId: contest._id,
    answers: { $ne: [] },
  })
    .sort({ score: -1, playedAt: 1 })
    .lean();

  const winners = [];
  for (const prize of contest.prizes || []) {
    const entry = ranked[prize.rank - 1];
    if (!entry) continue;
    const user = await User.findById(entry.userId);
    if (!user) continue;
    await applyCoins(
      user,
      prize.coins,
      `Contest prize: ${contest.name} (rank ${prize.rank})`,
      'contest',
      contest._id
    );
    await user.save();
    winners.push({ rank: prize.rank, userId: String(user._id), coins: prize.coins });
  }

  contest.prizeDistributed = true;
  await contest.save();

  res.json({ distributed: true, winners });
});

module.exports = { list, create, detail, join, submit, leaderboard, distribute };
