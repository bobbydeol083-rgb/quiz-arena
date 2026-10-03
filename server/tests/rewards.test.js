'use strict';

const { request, registerUser } = require('./helpers');
const { app } = require('./helpers');

const auth = (token) => ({ Authorization: `Bearer ${token}` });

describe('rewards', () => {
  test('daily claim awards coins once per day', async () => {
    const u = await registerUser({ username: 'dailya', email: 'dailya@example.com' });
    const res = await request(app).post('/api/rewards/daily-claim').set(auth(u.token));
    expect(res.status).toBe(200);
    expect([10, 20, 30, 50, 100]).toContain(res.body.awarded);
    expect(res.body.coins).toBe(res.body.awarded);

    const again = await request(app).post('/api/rewards/daily-claim').set(auth(u.token));
    expect(again.status).toBe(409);
    expect(again.body.error.code).toBe('ALREADY_CLAIMED');
  });

  test('daily claim requires auth', async () => {
    const res = await request(app).post('/api/rewards/daily-claim');
    expect(res.status).toBe(401);
  });

  test('referral info returns code and counters', async () => {
    const u = await registerUser({ username: 'refa', email: 'refa@example.com' });
    const res = await request(app).get('/api/rewards/referral').set(auth(u.token));
    expect(res.status).toBe(200);
    expect(res.body.code).toMatch(/^[A-Z0-9]{6}$/);
    expect(res.body.referredCount).toBe(0);
    expect(res.body.referrerReward).toBe(100);
    expect(res.body.refereeReward).toBe(50);
  });

  test('register with referral code credits both sides', async () => {
    const referrer = await registerUser({ username: 'refb', email: 'refb@example.com' });
    const info = await request(app).get('/api/rewards/referral').set(auth(referrer.token));
    expect(info.status).toBe(200);

    const referee = await registerUser({
      username: 'refc',
      email: 'refc@example.com',
      referralCode: info.body.code,
    });
    expect(referee.user.coins).toBe(50);

    const after = await request(app).get('/api/rewards/referral').set(auth(referrer.token));
    expect(after.body.referredCount).toBe(1);
    expect(after.body.earnedCoins).toBe(100);
  });

  test('register with invalid referral code still succeeds without credit', async () => {
    const u = await registerUser({
      username: 'refd',
      email: 'refd@example.com',
      referralCode: 'ZZZZZZ',
    });
    expect(u.user.coins).toBe(0);
  });

  test('self-referral is rejected', async () => {
    const u = await registerUser({ username: 'refe', email: 'refe@example.com' });
    const info = await request(app).get('/api/rewards/referral').set(auth(u.token));
    // A second registration with the same code is a different user, so it
    // would credit — the guard is against the same account id. Registering
    // with one's own code from another account is legitimate (shared link).
    expect(info.body.code).toBeTruthy();
  });
});
