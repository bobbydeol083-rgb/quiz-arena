'use strict';

const crypto = require('crypto');
const GamePack = require('../models/GamePack');
const { PACK_MODES } = require('../models/GamePack');
const { sanitizePackQuestions } = require('../utils/serialize');
const { errorBody, asyncHandler } = require('../utils/http');

const MAX_PER_PAGE = 30;

function slugify(title) {
  const base = String(title || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48) || 'pack';
  return `${base}-${crypto.randomInt(1000, 9999)}`;
}

function validateQuestions(questions) {
  if (!Array.isArray(questions) || questions.length < 5 || questions.length > 50) {
    return 'questions must be an array of 5–50 items';
  }
  for (let i = 0; i < questions.length; i++) {
    const q = questions[i] || {};
    if (typeof q.question !== 'string' || q.question.trim().length === 0 || q.question.length > 500) {
      return `questions[${i}].question must be a non-empty string (max 500 chars)`;
    }
    if (!Array.isArray(q.options) || q.options.length !== 4 || q.options.some((o) => typeof o !== 'string' || o.trim().length === 0)) {
      return `questions[${i}].options must be exactly 4 non-empty strings`;
    }
    if (!Number.isInteger(q.answerIndex) || q.answerIndex < 0 || q.answerIndex > 3) {
      return `questions[${i}].answerIndex must be an integer 0–3`;
    }
    if (q.explanation != null && (typeof q.explanation !== 'string' || q.explanation.length > 500)) {
      return `questions[${i}].explanation must be a string (max 500 chars)`;
    }
  }
  return null;
}

function packDetail(pack, { includeAnswers }) {
  const card = pack.toCard();
  return {
    ...card,
    questions: sanitizePackQuestions(pack.questions, { includeAnswers }),
  };
}

/** POST /api/packs — create a draft pack (auth). */
const create = asyncHandler(async (req, res) => {
  const { title, description = '', label = 'Custom', mode = 'quiz', questions } = req.body || {};
  if (typeof title !== 'string' || title.trim().length < 3 || title.length > 80) {
    return res.status(422).json(errorBody('VALIDATION_ERROR', 'title must be 3–80 characters'));
  }
  if (description != null && (typeof description !== 'string' || description.length > 500)) {
    return res.status(422).json(errorBody('VALIDATION_ERROR', 'description must be a string (max 500 chars)'));
  }
  if (label != null && (typeof label !== 'string' || label.length > 40)) {
    return res.status(422).json(errorBody('VALIDATION_ERROR', 'label must be a string (max 40 chars)'));
  }
  if (!PACK_MODES.includes(mode)) {
    return res.status(422).json(errorBody('VALIDATION_ERROR', `mode must be one of: ${PACK_MODES.join(', ')}`));
  }
  const qErr = validateQuestions(questions);
  if (qErr) return res.status(422).json(errorBody('VALIDATION_ERROR', qErr));

  const pack = await GamePack.create({
    title: title.trim(),
    slug: slugify(title),
    description: typeof description === 'string' ? description.trim() : '',
    label: typeof label === 'string' && label.trim() ? label.trim() : 'Custom',
    mode,
    questions,
    author: req.user.id,
    status: 'draft',
  });
  res.status(201).json(packDetail(pack, { includeAnswers: true }));
});

/** GET /api/packs — browse published packs. */
const list = asyncHandler(async (req, res) => {
  const { search, mode, sort = 'popular' } = req.query;
  let { page = 1, limit = 20 } = req.query;
  page = Math.max(1, parseInt(page, 10) || 1);
  limit = Math.max(1, Math.min(MAX_PER_PAGE, parseInt(limit, 10) || 20));

  const filter = { status: 'published' };
  if (mode && PACK_MODES.includes(mode)) filter.mode = mode;
  if (search && String(search).trim()) {
    filter.$text = { $search: String(search).trim() };
  }
  const sortSpec = sort === 'newest' ? { createdAt: -1 } : { installs: -1, createdAt: -1 };

  const [packs, total] = await Promise.all([
    GamePack.find(filter).populate('author', 'username').sort(sortSpec).skip((page - 1) * limit).limit(limit),
    GamePack.countDocuments(filter),
  ]);
  res.json({ packs: packs.map((p) => p.toCard()), page, limit, total });
});

/** GET /api/packs/mine — my drafts + published packs (auth). */
const mine = asyncHandler(async (req, res) => {
  const packs = await GamePack.find({ author: req.user.id }).sort({ updatedAt: -1 });
  res.json({ packs: packs.map((p) => ({ ...p.toCard(), status: p.status })) });
});

/** GET /api/packs/:id — pack detail. Answers only visible to the author. */
const get = asyncHandler(async (req, res) => {
  const pack = await GamePack.findById(req.params.id).populate('author', 'username');
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  const isAuthor = req.user && String(pack.author._id || pack.author) === String(req.user.id);
  if (pack.status !== 'published' && !isAuthor) {
    return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  }
  res.json(packDetail(pack, { includeAnswers: !!isAuthor }));
});

/** PUT /api/packs/:id — update a draft (auth, author only). */
const update = asyncHandler(async (req, res) => {
  const pack = await GamePack.findById(req.params.id);
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  if (String(pack.author) !== String(req.user.id)) {
    return res.status(403).json(errorBody('FORBIDDEN', 'Only the author can edit this pack'));
  }
  if (pack.status !== 'draft') {
    return res.status(409).json(errorBody('PACK_PUBLISHED', 'Unpublish the pack before editing'));
  }
  const { title, description, label, mode, questions } = req.body || {};
  if (title !== undefined) {
    if (typeof title !== 'string' || title.trim().length < 3 || title.length > 80) {
      return res.status(422).json(errorBody('VALIDATION_ERROR', 'title must be 3–80 characters'));
    }
    pack.title = title.trim();
  }
  if (description !== undefined) {
    if (typeof description !== 'string' || description.length > 500) {
      return res.status(422).json(errorBody('VALIDATION_ERROR', 'description must be a string (max 500 chars)'));
    }
    pack.description = description.trim();
  }
  if (label !== undefined) {
    if (typeof label !== 'string' || label.length > 40) {
      return res.status(422).json(errorBody('VALIDATION_ERROR', 'label must be a string (max 40 chars)'));
    }
    pack.label = label.trim() || 'Custom';
  }
  if (mode !== undefined) {
    if (!PACK_MODES.includes(mode)) {
      return res.status(422).json(errorBody('VALIDATION_ERROR', `mode must be one of: ${PACK_MODES.join(', ')}`));
    }
    pack.mode = mode;
  }
  if (questions !== undefined) {
    const qErr = validateQuestions(questions);
    if (qErr) return res.status(422).json(errorBody('VALIDATION_ERROR', qErr));
    pack.questions = questions;
  }
  pack.version += 1;
  await pack.save();
  res.json(packDetail(pack, { includeAnswers: true }));
});

/** POST /api/packs/:id/publish — draft → published (auth, author only). */
const publish = asyncHandler(async (req, res) => {
  const pack = await GamePack.findById(req.params.id).populate('author', 'username');
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  if (String(pack.author._id || pack.author) !== String(req.user.id)) {
    return res.status(403).json(errorBody('FORBIDDEN', 'Only the author can publish this pack'));
  }
  const qErr = validateQuestions(pack.questions);
  if (qErr) return res.status(422).json(errorBody('VALIDATION_ERROR', qErr));
  pack.status = 'published';
  await pack.save();
  res.json(packDetail(pack, { includeAnswers: true }));
});

/** POST /api/packs/:id/unpublish — published → draft (auth, author only). */
const unpublish = asyncHandler(async (req, res) => {
  const pack = await GamePack.findById(req.params.id);
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  if (String(pack.author) !== String(req.user.id)) {
    return res.status(403).json(errorBody('FORBIDDEN', 'Only the author can unpublish this pack'));
  }
  pack.status = 'draft';
  await pack.save();
  res.json(packDetail(pack, { includeAnswers: true }));
});

/** DELETE /api/packs/:id — delete (auth, author only). */
const remove = asyncHandler(async (req, res) => {
  const pack = await GamePack.findById(req.params.id);
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  if (String(pack.author) !== String(req.user.id)) {
    return res.status(403).json(errorBody('FORBIDDEN', 'Only the author can delete this pack'));
  }
  await pack.deleteOne();
  res.json({ deleted: true });
});

/**
 * POST /api/packs/:id/install — "install" a published pack (auth).
 * Bumps the install counter and returns the full pack WITH answers so the
 * app can cache it locally and grade offline play. Only published packs
 * can be installed.
 */
const install = asyncHandler(async (req, res) => {
  const pack = await GamePack.findByIdAndUpdate(
    { _id: req.params.id, status: 'published' },
    { $inc: { installs: 1 } },
    { new: true }
  ).populate('author', 'username');
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  res.json(packDetail(pack, { includeAnswers: true }));
});

/** POST /api/packs/:id/played — bump the play counter (auth). */
const played = asyncHandler(async (req, res) => {
  const pack = await GamePack.findByIdAndUpdate(
    { _id: req.params.id, status: 'published' },
    { $inc: { plays: 1 } },
    { new: true }
  ).populate('author', 'username');
  if (!pack) return res.status(404).json(errorBody('PACK_NOT_FOUND', 'Pack not found'));
  res.json(packDetail(pack, { includeAnswers: false }));
});

module.exports = { create, list, mine, get, update, publish, unpublish, remove, install, played, validateQuestions };
