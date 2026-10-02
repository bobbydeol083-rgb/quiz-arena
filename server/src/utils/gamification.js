'use strict';

// ---------------------------------------------------------------------------
// Gamification engine — single source of truth for XP, levels, coins,
// streaks and badges. Used by both the REST quiz-submit flow and the
// Socket.io realtime game flow, and covered by unit tests.
// ---------------------------------------------------------------------------

const LEVEL_THRESHOLDS = [0, 100, 250, 500, 1000, 1800, 3000, 5000]; // min XP per level (1-indexed)
const LEVEL_TIERS = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Masters', 'Grandmaster', 'Legend'];
const MAX_LEVEL = LEVEL_THRESHOLDS.length;

const DIFFICULTY_MULTIPLIER = { easy: 1, medium: 1.5, hard: 2 };

// Minimum XP required to reach a 1-indexed level. Returns null past max level.
function xpForLevel(level) {
  if (!Number.isInteger(level) || level < 1) return null;
  if (level > MAX_LEVEL) return null;
  return LEVEL_THRESHOLDS[level - 1];
}

// Level (1..8) for a given total XP.
function levelForXp(xp) {
  const total = Math.max(0, Math.floor(xp || 0));
  let level = 1;
  for (let i = 0; i < LEVEL_THRESHOLDS.length; i++) {
    if (total >= LEVEL_THRESHOLDS[i]) level = i + 1;
  }
  return level;
}

function tierForLevel(level) {
  if (!Number.isInteger(level) || level < 1 || level > MAX_LEVEL) return LEVEL_TIERS[0];
  return LEVEL_TIERS[level - 1];
}

// Advance a daily streak. Same calendar day -> unchanged; yesterday -> +1;
// anything older (or never played) -> reset to 1.
function nextStreak(streak, now = new Date()) {
  const current = now instanceof Date ? now : new Date(now);
  const count = (streak && Number.isInteger(streak.count) ? streak.count : 0);
  const lastPlayedAt = streak && streak.lastPlayedAt ? new Date(streak.lastPlayedAt) : null;

  const startOfDay = (d) => {
    const c = new Date(d);
    c.setHours(0, 0, 0, 0);
    return c.getTime();
  };

  if (!lastPlayedAt || Number.isNaN(lastPlayedAt.getTime())) {
    return { count: 1, lastPlayedAt: current };
  }
  const diffDays = Math.round((startOfDay(current) - startOfDay(lastPlayedAt)) / 86400000);
  if (diffDays <= 0) return { count, lastPlayedAt: current };
  if (diffDays === 1) return { count: count + 1, lastPlayedAt: current };
  return { count: 1, lastPlayedAt: current };
}

// Grade a submission against the server-side question map.
// answers: [{ questionId, selectedIndex, timeMs }]
// questionMap: Map<questionIdString, { answerIndex }>
function gradeSubmission({ answers, questionMap, difficulty = 'medium', streakCount = 0 }) {
  const mult = DIFFICULTY_MULTIPLIER[difficulty] || 1;
  let correct = 0;
  let speedBonus = 0;
  let score = 0;
  let totalTime = 0;
  const perQuestion = [];

  for (const a of answers) {
    const q = questionMap.get(String(a.questionId));
    const timeMs = Math.max(0, Number(a.timeMs) || 0);
    const isCorrect = !!q && Number(a.selectedIndex) === q.answerIndex;
    if (isCorrect) {
      correct += 1;
      // Up to +50 time bonus per correct answer, decaying over 10s.
      const timeBonus = Math.round(50 * (1 - Math.min(timeMs, 10000) / 10000));
      score += 100 + Math.max(0, timeBonus);
      if (timeMs < 5000) speedBonus += 2;
    }
    totalTime += timeMs;
    perQuestion.push({ questionId: String(a.questionId), correct: isCorrect, timeMs });
  }

  const total = answers.length;
  const base = correct * 10;
  const streakBonus = Math.min(Math.max(0, streakCount | 0), 10) * 2;
  const xp = Math.round((base + streakBonus + speedBonus) * mult);
  const avgTimeMs = total ? Math.round(totalTime / total) : 0;

  return { score, correct, total, xp, avgTimeMs, perQuestion };
}

function coinsForResult({ correct, perfect = false, duelWin = false }) {
  return Math.max(0, correct | 0) * 2 + (perfect ? 5 : 0) + (duelWin ? 10 : 0);
}

// Badge rules. Returns the list of badge keys newly earned (mutates user.badges).
function awardBadges(user, { mode, correct, total, avgTimeMs, duelWin = false, streakCount = 0, bluffFooled = 0 }) {
  const held = new Set(user.badges || []);
  const newly = [];
  const grant = (key) => {
    if (!held.has(key)) {
      held.add(key);
      newly.push(key);
    }
  };

  if ((user.stats?.played || 0) >= 1) grant('first_blood');
  if (total >= 10 && correct / total >= 0.8) grant('sharpshooter');
  if (total >= 5 && correct === total) grant('perfectionist');
  if (total >= 5 && avgTimeMs < 5000) grant('speed_demon');
  if (streakCount >= 3) grant('streak_3');
  if (streakCount >= 7) grant('streak_7');
  if (mode === 'marathon' && total >= 15) grant('marathoner');
  if (duelWin) grant('duelist');
  if ((user.stats?.correctAnswers || 0) >= 100) grant('scholar');
  // Bluff & Brain titles ladder — persistent badges for deception craft.
  if (mode === 'bluff' && bluffFooled >= 4) grant('fibber');
  if (mode === 'bluff' && bluffFooled >= 10) grant('deceiver');
  if (mode === 'bluff' && total >= 3 && correct === total) grant('truth_hunter');

  user.badges = Array.from(held);
  return newly;
}

// Apply a graded game result to a (mutated, not saved) user document.
// Returns the reward summary for the API response.
function applyGameResult(user, graded, { mode, duelWin = false, now = new Date(), bluffFooled = 0 } = {}) {
  const at = now instanceof Date ? now : new Date(now);
  const xpBefore = Math.max(0, user.xp || 0);
  const oldLevel = levelForXp(xpBefore);

  const streak = nextStreak(user.streak, at);
  user.streak = { count: streak.count, lastPlayedAt: streak.lastPlayedAt };

  user.stats = user.stats || {};
  user.stats.played = (user.stats.played || 0) + 1;
  user.stats.correctAnswers = (user.stats.correctAnswers || 0) + graded.correct;
  user.stats.totalAnswers = (user.stats.totalAnswers || 0) + graded.total;
  user.stats.bestStreak = Math.max(user.stats.bestStreak || 0, streak.count);

  const coins = coinsForResult({ correct: graded.correct, perfect: graded.total > 0 && graded.correct === graded.total, duelWin });
  user.xp = xpBefore + graded.xp;
  const newLevel = levelForXp(user.xp);
  const levelUp = newLevel > oldLevel;
  user.level = newLevel;
  user.coins = (user.coins || 0) + coins;
  user.lastSeen = at;

  const newBadges = awardBadges(user, {
    mode,
    correct: graded.correct,
    total: graded.total,
    avgTimeMs: graded.avgTimeMs,
    duelWin,
    streakCount: streak.count,
    bluffFooled,
  });

  return {
    xpEarned: graded.xp,
    coinsEarned: coins,
    newBadges,
    levelUp,
    oldLevel,
    newLevel,
    tier: tierForLevel(newLevel),
    streak: { count: streak.count, lastPlayedAt: streak.lastPlayedAt },
  };
}

module.exports = {
  LEVEL_THRESHOLDS,
  LEVEL_TIERS,
  MAX_LEVEL,
  DIFFICULTY_MULTIPLIER,
  xpForLevel,
  levelForXp,
  tierForLevel,
  nextStreak,
  gradeSubmission,
  coinsForResult,
  awardBadges,
  applyGameResult,
};
