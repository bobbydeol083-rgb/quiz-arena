'use strict';

const { tierForLevel } = require('./gamification');

function idOf(doc) {
  return String(doc._id || doc.id);
}

// Public user shape for API responses. includeEmail/includeStats widen it for /me.
function publicUser(user, { includeEmail = false, includeStats = false } = {}) {
  const u = typeof user.toObject === 'function' ? user.toObject() : user;
  const out = {
    id: idOf(u),
    username: u.username,
    avatar: u.avatar,
    xp: u.xp || 0,
    level: u.level || 1,
    tier: tierForLevel(u.level || 1),
    coins: u.coins || 0,
    streak: {
      count: u.streak?.count || 0,
      lastPlayedAt: u.streak?.lastPlayedAt || null,
    },
    badges: u.badges || [],
    online: !!u.online,
    lastSeen: u.lastSeen || null,
  };
  if (includeEmail) out.email = u.email;
  if (includeEmail && u.referralCode) out.referralCode = u.referralCode;
  if (includeStats) {
    out.stats = {
      played: u.stats?.played || 0,
      won: u.stats?.won || 0,
      correctAnswers: u.stats?.correctAnswers || 0,
      totalAnswers: u.stats?.totalAnswers || 0,
      bestStreak: u.stats?.bestStreak || 0,
    };
  }
  return out;
}

// Strip answerIndex (and any other internals) before sending questions to clients.
function sanitizeQuestion(q) {
  const o = typeof q.toObject === 'function' ? q.toObject() : q;
  const category = o.category && typeof o.category === 'object'
    ? idOf(o.category)
    : o.category;
  return {
    id: idOf(o),
    category: category ? String(category) : null,
    difficulty: o.difficulty,
    question: o.question,
    options: o.options,
    explanation: o.explanation || '',
  };
}

function sanitizeQuestions(list) {
  return (list || []).map(sanitizeQuestion);
}

// Pack questions: strip answerIndex unless the caller is entitled to it
// (pack author, or an installed copy the app grades locally/offline).
function sanitizePackQuestion(q, { includeAnswers = false } = {}) {
  const o = typeof q.toObject === 'function' ? q.toObject() : q;
  const out = {
    question: o.question,
    options: o.options,
    explanation: o.explanation || '',
  };
  if (includeAnswers) out.answerIndex = o.answerIndex;
  return out;
}

function sanitizePackQuestions(list, opts) {
  return (list || []).map((q) => sanitizePackQuestion(q, opts));
}

module.exports = { publicUser, sanitizeQuestion, sanitizeQuestions, sanitizePackQuestion, sanitizePackQuestions };
