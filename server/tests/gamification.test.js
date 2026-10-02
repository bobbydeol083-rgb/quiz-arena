'use strict';

const g = require('../src/utils/gamification');

describe('levels', () => {
  test('levelForXp follows thresholds [0,100,250,500,1000,1800,3000,5000]', () => {
    expect(g.levelForXp(0)).toBe(1);
    expect(g.levelForXp(99)).toBe(1);
    expect(g.levelForXp(100)).toBe(2);
    expect(g.levelForXp(249)).toBe(2);
    expect(g.levelForXp(250)).toBe(3);
    expect(g.levelForXp(500)).toBe(4);
    expect(g.levelForXp(1000)).toBe(5);
    expect(g.levelForXp(1800)).toBe(6);
    expect(g.levelForXp(3000)).toBe(7);
    expect(g.levelForXp(4999)).toBe(7);
    expect(g.levelForXp(5000)).toBe(8);
    expect(g.levelForXp(999999)).toBe(8);
    expect(g.levelForXp(-5)).toBe(1);
  });

  test('xpForLevel returns minimum xp per level', () => {
    expect(g.xpForLevel(1)).toBe(0);
    expect(g.xpForLevel(2)).toBe(100);
    expect(g.xpForLevel(8)).toBe(5000);
    expect(g.xpForLevel(9)).toBeNull();
    expect(g.xpForLevel(0)).toBeNull();
  });

  test('tierForLevel names', () => {
    expect(g.tierForLevel(1)).toBe('Bronze');
    expect(g.tierForLevel(4)).toBe('Platinum');
    expect(g.tierForLevel(8)).toBe('Legend');
  });
});

describe('nextStreak', () => {
  const day = (y, m, d, h = 12) => new Date(y, m, d, h);

  test('first ever game → streak 1', () => {
    const s = g.nextStreak(null, day(2026, 9, 2));
    expect(s.count).toBe(1);
  });

  test('same calendar day → unchanged count', () => {
    const s = g.nextStreak({ count: 4, lastPlayedAt: day(2026, 9, 2, 9) }, day(2026, 9, 2, 20));
    expect(s.count).toBe(4);
  });

  test('yesterday → increments', () => {
    const s = g.nextStreak({ count: 4, lastPlayedAt: day(2026, 9, 1) }, day(2026, 9, 2));
    expect(s.count).toBe(5);
  });

  test('gap of 2+ days → resets to 1', () => {
    const s = g.nextStreak({ count: 9, lastPlayedAt: day(2026, 8, 30) }, day(2026, 9, 2));
    expect(s.count).toBe(1);
  });
});

describe('gradeSubmission', () => {
  const map = new Map([
    ['q1', { answerIndex: 0 }],
    ['q2', { answerIndex: 2 }],
    ['q3', { answerIndex: 1 }],
  ]);

  test('xp = (correct*10 + streakBonus + speedBonus) * difficulty multiplier', () => {
    const graded = g.gradeSubmission({
      answers: [
        { questionId: 'q1', selectedIndex: 0, timeMs: 2000 }, // correct, fast
        { questionId: 'q2', selectedIndex: 2, timeMs: 9000 }, // correct, slow
        { questionId: 'q3', selectedIndex: 3, timeMs: 1000 }, // wrong
      ],
      questionMap: map,
      difficulty: 'medium',
      streakCount: 3,
    });
    // base 20 + streakBonus 6 + speedBonus 2 = 28; * 1.5 = 42
    expect(graded.correct).toBe(2);
    expect(graded.total).toBe(3);
    expect(graded.xp).toBe(42);
    expect(graded.score).toBeGreaterThan(200);
    expect(graded.avgTimeMs).toBe(4000);
  });

  test('hard multiplier doubles xp; unknown question counts as wrong', () => {
    const easy = g.gradeSubmission({
      answers: [{ questionId: 'q1', selectedIndex: 0, timeMs: 1000 }],
      questionMap: map,
      difficulty: 'easy',
      streakCount: 0,
    });
    const hard = g.gradeSubmission({
      answers: [{ questionId: 'q1', selectedIndex: 0, timeMs: 1000 }],
      questionMap: map,
      difficulty: 'hard',
      streakCount: 0,
    });
    // easy: (10 + 0 + 2) * 1 = 12 ; hard: 12 * 2 = 24
    expect(easy.xp).toBe(12);
    expect(hard.xp).toBe(24);

    const unknown = g.gradeSubmission({
      answers: [{ questionId: 'nope', selectedIndex: 0, timeMs: 100 }],
      questionMap: map,
      difficulty: 'easy',
      streakCount: 0,
    });
    expect(unknown.correct).toBe(0);
    expect(unknown.xp).toBe(0);
  });
});

describe('coinsForResult', () => {
  test('correct*2 + bonuses', () => {
    expect(g.coinsForResult({ correct: 7 })).toBe(14);
    expect(g.coinsForResult({ correct: 10, perfect: true })).toBe(25);
    expect(g.coinsForResult({ correct: 6, duelWin: true })).toBe(22);
  });
});

describe('awardBadges', () => {
  const mkUser = (over = {}) => ({
    badges: [],
    stats: { played: 1, correctAnswers: 0, ...(over.stats || {}) },
    ...over,
  });

  test('first_blood on first game', () => {
    const u = mkUser();
    expect(g.awardBadges(u, { mode: 'solo', correct: 1, total: 5, avgTimeMs: 9000 })).toContain('first_blood');
  });

  test('perfectionist, sharpshooter, speed_demon', () => {
    const u = mkUser({ stats: { played: 5, correctAnswers: 40 } });
    const badges = g.awardBadges(u, { mode: 'solo', correct: 10, total: 10, avgTimeMs: 3000 });
    expect(badges).toEqual(expect.arrayContaining(['perfectionist', 'sharpshooter', 'speed_demon']));
  });

  test('streak badges, marathoner, duelist, scholar', () => {
    const u = mkUser({ stats: { played: 9, correctAnswers: 100 } });
    const badges = g.awardBadges(u, { mode: 'marathon', correct: 15, total: 15, avgTimeMs: 9000, duelWin: true, streakCount: 7 });
    expect(badges).toEqual(expect.arrayContaining(['streak_3', 'streak_7', 'marathoner', 'duelist', 'scholar']));
  });

  test('badges are not granted twice', () => {
    const u = mkUser({ badges: ['first_blood'], stats: { played: 2, correctAnswers: 5 } });
    const badges = g.awardBadges(u, { mode: 'solo', correct: 2, total: 5, avgTimeMs: 9000 });
    expect(badges).not.toContain('first_blood');
    expect(u.badges.filter((b) => b === 'first_blood')).toHaveLength(1);
  });
});

describe('applyGameResult', () => {
  test('mutates user and reports level-up', () => {
    const user = {
      xp: 95, level: 1, coins: 0, badges: [],
      streak: { count: 2, lastPlayedAt: new Date(Date.now() - 86400000) },
      stats: { played: 0, won: 0, correctAnswers: 0, totalAnswers: 0, bestStreak: 2 },
    };
    const graded = { score: 300, correct: 3, total: 5, xp: 20, avgTimeMs: 4000, perQuestion: [] };
    const r = g.applyGameResult(user, graded, { mode: 'solo', now: new Date() });

    expect(user.xp).toBe(115);
    expect(user.level).toBe(2);
    expect(r.levelUp).toBe(true);
    expect(r.oldLevel).toBe(1);
    expect(r.newLevel).toBe(2);
    expect(r.tier).toBe('Silver');
    expect(user.coins).toBe(6);
    expect(user.streak.count).toBe(3);
    expect(user.stats.played).toBe(1);
    expect(user.stats.bestStreak).toBe(3);
    expect(r.newBadges).toContain('first_blood');
  });
});
