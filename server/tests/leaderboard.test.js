'use strict';

const { app, request, registerUser } = require('./helpers');
const User = require('../src/models/User');
const GameResult = require('../src/models/GameResult');

describe('leaderboard', () => {
  test('weekly scope uses last-7d GameResult xp; alltime uses user.xp', async () => {
    const a = await registerUser({ username: 'lb_a', email: 'lb_a@example.com' });
    const b = await registerUser({ username: 'lb_b', email: 'lb_b@example.com' });
    const c = await registerUser({ username: 'lb_c', email: 'lb_c@example.com' });

    await User.findByIdAndUpdate(a.user.id, { xp: 50 });
    await User.findByIdAndUpdate(b.user.id, { xp: 900 });
    await User.findByIdAndUpdate(c.user.id, { xp: 300 });

    const now = Date.now();
    const mk = (userId, xpEarned, ageMs) => GameResult.create({
      user: userId, mode: 'solo', difficulty: 'medium',
      score: 100, correct: 5, total: 5, xpEarned, coinsEarned: 10,
      createdAt: new Date(now - ageMs),
    });
    await mk(a.user.id, 500, 1000); // recent
    await mk(b.user.id, 100, 1000); // recent
    await mk(c.user.id, 999, 10 * 24 * 3600 * 1000); // 10 days old → excluded from weekly

    const weekly = await request(app)
      .get('/api/leaderboard?scope=weekly&limit=50')
      .set('Authorization', `Bearer ${a.token}`);
    expect(weekly.status).toBe(200);
    expect(weekly.body.scope).toBe('weekly');
    expect(weekly.body.entries.map((e) => e.user.username)).toEqual(['lb_a', 'lb_b']);
    expect(weekly.body.entries[0]).toMatchObject({ rank: 1, points: 500 });
    expect(weekly.body.me).toMatchObject({ rank: 1, points: 500 });

    const alltime = await request(app)
      .get('/api/leaderboard?scope=alltime&limit=50')
      .set('Authorization', `Bearer ${c.token}`);
    expect(alltime.status).toBe(200);
    expect(alltime.body.entries.map((e) => e.user.username)).toEqual(['lb_b', 'lb_c', 'lb_a']);
    expect(alltime.body.me).toMatchObject({ rank: 2, points: 300 });
  });

  test('leaderboard is public but me is null without token', async () => {
    const res = await request(app).get('/api/leaderboard?scope=alltime');
    expect(res.status).toBe(200);
    expect(res.body.me).toMatchObject({ rank: null, points: 0 });
  });

  test('invalid scope → 400', async () => {
    const res = await request(app).get('/api/leaderboard?scope=monthly');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });
});
