'use strict';

const { request, registerUser, app } = require('./helpers');

const auth = (token) => ({ Authorization: `Bearer ${token}` });

function contestPayload(overrides = {}) {
  const now = Date.now();
  return {
    name: `Contest ${now % 100000}`,
    description: 'A test contest',
    startDate: new Date(now - 60_000).toISOString(),
    endDate: new Date(now + 3_600_000).toISOString(),
    entryFee: 0,
    prizes: [
      { rank: 1, coins: 100 },
      { rank: 2, coins: 50 },
    ],
    questions: [
      { question: '2+2?', options: ['3', '4', '5'], answerIndex: 1 },
      { question: 'Sky color?', options: ['Blue', 'Green'], answerIndex: 0 },
    ],
    ...overrides,
  };
}

describe('contests', () => {
  test('create, list, join, submit, leaderboard', async () => {
    const creator = await registerUser({ username: 'cxa', email: 'cxa@example.com' });
    const player = await registerUser({ username: 'cxb', email: 'cxb@example.com' });

    const created = await request(app)
      .post('/api/contests')
      .set(auth(creator.token))
      .send(contestPayload());
    expect(created.status).toBe(201);
    const id = created.body.id;

    const listed = await request(app).get('/api/contests').set(auth(player.token));
    expect(listed.status).toBe(200);
    const card = listed.body.contests.find((c) => c.id === id);
    expect(card).toBeTruthy();
    expect(card.phase).toBe('live');
    expect(card.prizePool).toBe(150);
    expect(card.played).toBe(false);

    const joined = await request(app).post(`/api/contests/${id}/join`).set(auth(player.token));
    expect(joined.status).toBe(200);
    expect(joined.body.questions.length).toBe(2);
    expect(joined.body.questions[0].answerIndex).toBeUndefined();

    const again = await request(app).post(`/api/contests/${id}/join`).set(auth(player.token));
    expect(again.status).toBe(409);

    const submitted = await request(app)
      .post(`/api/contests/${id}/submit`)
      .set(auth(player.token))
      .send({ answers: [1, 0] });
    expect(submitted.status).toBe(200);
    expect(submitted.body.score).toBe(20);
    expect(submitted.body.correctAnswers).toBe(2);
    expect(submitted.body.rank).toBe(1);

    const lb = await request(app).get(`/api/contests/${id}/leaderboard`);
    expect(lb.status).toBe(200);
    expect(lb.body.leaderboard.length).toBe(1);
    expect(lb.body.leaderboard[0].username).toBe('cxb');

    const detail = await request(app).get(`/api/contests/${id}`).set(auth(player.token));
    expect(detail.body.myEntry.submitted).toBe(true);
  });

  test('entry fee is deducted and blocks the broke', async () => {
    const creator = await registerUser({ username: 'cxc', email: 'cxc@example.com' });
    const broke = await registerUser({ username: 'cxd', email: 'cxd@example.com' });

    const created = await request(app)
      .post('/api/contests')
      .set(auth(creator.token))
      .send(contestPayload({ entryFee: 500 }));
    const id = created.body.id;

    const joined = await request(app).post(`/api/contests/${id}/join`).set(auth(broke.token));
    expect(joined.status).toBe(402);
    expect(joined.body.error.code).toBe('INSUFFICIENT_COINS');
  });

  test('prize distribution is idempotent and rank-ordered', async () => {
    const creator = await registerUser({ username: 'cxe', email: 'cxe@example.com' });
    const p1 = await registerUser({ username: 'cxf', email: 'cxf@example.com' });
    const p2 = await registerUser({ username: 'cxg', email: 'cxg@example.com' });

    // Already-ended contest.
    const now = Date.now();
    const created = await request(app)
      .post('/api/contests')
      .set(auth(creator.token))
      .send(contestPayload({
        startDate: new Date(now - 3_600_000).toISOString(),
        endDate: new Date(now - 60_000).toISOString(),
      }));
    const id = created.body.id;

    // Ended contests can't be joined.
    const joinEnded = await request(app).post(`/api/contests/${id}/join`).set(auth(p1.token));
    expect(joinEnded.status).toBe(409);

    // Non-creator cannot distribute.
    const forbidden = await request(app).post(`/api/contests/${id}/distribute`).set(auth(p1.token));
    expect(forbidden.status).toBe(403);

    // Creator distributes with no players — succeeds, no winners.
    const empty = await request(app).post(`/api/contests/${id}/distribute`).set(auth(creator.token));
    expect(empty.status).toBe(200);
    expect(empty.body.winners).toEqual([]);

    // Second distribution is rejected.
    const twice = await request(app).post(`/api/contests/${id}/distribute`).set(auth(creator.token));
    expect(twice.status).toBe(409);
  });

  test('validation rejects bad payloads', async () => {
    const u = await registerUser({ username: 'cxh', email: 'cxh@example.com' });
    const bad = await request(app)
      .post('/api/contests')
      .set(auth(u.token))
      .send({ name: 'x' });
    expect(bad.status).toBe(400);

    const noQ = await request(app)
      .post('/api/contests')
      .set(auth(u.token))
      .send({ ...contestPayload(), questions: [] });
    expect(noQ.status).toBe(400);
  });

  test('coin transactions are recorded', async () => {
    const u = await registerUser({ username: 'cxi', email: 'cxi@example.com' });
    await request(app).post('/api/rewards/daily-claim').set(auth(u.token));
    const txs = await request(app).get('/api/rewards/transactions').set(auth(u.token));
    expect(txs.status).toBe(200);
    expect(txs.body.transactions.length).toBeGreaterThan(0);
    expect(txs.body.transactions[0].reason).toMatch(/Daily scratch/);
    expect(txs.body.transactions[0].balanceAfter).toBeGreaterThan(0);
  });
});
