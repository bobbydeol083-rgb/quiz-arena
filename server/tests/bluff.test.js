'use strict';

// Fast phases for tests (bluff.js reads these at require time).
process.env.BLUFF_REVEAL_MS = '150';

const http = require('http');
const { Server } = require('socket.io');
const { io: ioClient } = require('socket.io-client');
const { registerUser } = require('./helpers');
const createApp = require('../src/app');
const initSocket = require('../src/socket');
const Category = require('../src/models/Category');
const Question = require('../src/models/Question');
const GameResult = require('../src/models/GameResult');

function once(socket, event, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`timed out waiting for ${event}`)), timeoutMs);
    socket.once(event, (data) => {
      clearTimeout(timer);
      resolve(data);
    });
  });
}

function emitAck(socket, event, payload) {
  return new Promise((resolve) => socket.emit(event, payload, (res) => resolve(res)));
}

describe('bluff & brain', () => {
  let httpServer;
  let port;
  let clients = [];

  beforeAll(async () => {
    const app = createApp();
    httpServer = http.createServer(app);
    const io = new Server(httpServer, { cors: { origin: '*' } });
    initSocket(io);
    await new Promise((resolve) => httpServer.listen(0, resolve));
    port = httpServer.address().port;

    const cat = await Category.create({ name: 'BluffCat', icon: '🎭', color: '#123456', description: 'bluff test' });
    for (let i = 0; i < 12; i++) {
      await Question.create({
        category: cat._id,
        difficulty: 'easy',
        question: `Bluff question ${i}?`,
        options: [`Truth ${i}`, `Wrong ${i} A`, `Wrong ${i} B`, `Wrong ${i} C`],
        answerIndex: 0,
        explanation: 'bluff',
      });
    }
  });

  afterAll(async () => {
    for (const c of clients) c.disconnect();
    clients = [];
    if (httpServer) await new Promise((resolve) => httpServer.close(resolve));
  });

  function connect() {
    const s = ioClient(`http://127.0.0.1:${port}`, { transports: ['websocket'] });
    clients.push(s);
    return s;
  }

  async function authedClient(user) {
    const s = connect();
    await once(s, 'connect');
    const res = await emitAck(s, 'authenticate', { token: user.token });
    expect(res.ok).toBe(true);
    return s;
  }

  test('full bluff game: write, vote, reveal, power-ups, scoring, end', async () => {
    const n = `${Date.now() % 100000}`;
    const host = await registerUser({ username: `bh${n}`.slice(0, 20), email: `bh${n}@example.com` });
    const p2 = await registerUser({ username: `b2${n}`.slice(0, 20), email: `b2${n}@example.com` });
    const p3 = await registerUser({ username: `b3${n}`.slice(0, 20), email: `b3${n}@example.com` });

    const sHost = await authedClient(host);
    const s2 = await authedClient(p2);
    const s3 = await authedClient(p3);
    const hostId = host.user.id;
    const p2Id = p2.user.id;
    const p3Id = p3.user.id;

    // Create a bluff room and have everyone join.
    const created = await emitAck(sHost, 'room:create', { mode: 'bluff' });
    expect(created.ok).toBe(true);
    const code = created.code;
    expect(await emitAck(s2, 'room:join', { code })).toMatchObject({ ok: true });
    expect(await emitAck(s3, 'room:join', { code })).toMatchObject({ ok: true });

    // Start -> write phase. Question must NOT leak the answer.
    const startP = once(sHost, 'bluff:start');
    const roundP = once(sHost, 'bluff:round');
    expect(await emitAck(sHost, 'room:start', {})).toMatchObject({ ok: true });
    const started = await startP;
    expect(started.totalRounds).toBe(5);
    const round1 = await roundP;
    expect(round1.round).toBe(1);
    expect(round1.question).toMatch(/Bluff question/);
    expect(round1).not.toHaveProperty('answerIndex');
    expect(round1).not.toHaveProperty('options');

    // ---- round 1: write phase ----
    expect(await emitAck(sHost, 'bluff:fake', { text: 'HostFake1' })).toMatchObject({ ok: true });
    expect(await emitAck(s2, 'bluff:fake', { text: 'P2Fake1' })).toMatchObject({ ok: true });
    const voteP = once(sHost, 'bluff:vote');
    expect(await emitAck(s3, 'bluff:fake', { text: 'P3Fake1' })).toMatchObject({ ok: true });
    const vote1 = await voteP;
    expect(vote1.options).toHaveLength(4);
    // Authorship hidden during voting.
    expect(vote1.options.every((o) => o.authorId === undefined)).toBe(true);
    const truthOpt = vote1.options.find((o) => o.id === 'truth');
    expect(truthOpt.text).toMatch(/^Truth \d+$/);
    const hostFakeId = `fake:${hostId}`;

    // Cannot vote for your own fake.
    const ownVote = await emitAck(sHost, 'bluff:vote', { optionId: hostFakeId });
    expect(ownVote.ok).toBe(false);
    expect(ownVote.error.code).toBe('BLUFF_OWN_FAKE');

    // Votes: host -> truth (+100), p2 -> host fake, p3 -> p2 fake.
    const revealP = once(sHost, 'bluff:reveal');
    expect(await emitAck(sHost, 'bluff:vote', { optionId: 'truth' })).toMatchObject({ ok: true });
    expect(await emitAck(s2, 'bluff:vote', { optionId: hostFakeId })).toMatchObject({ ok: true });
    expect(await emitAck(s3, 'bluff:vote', { optionId: `fake:${p2Id}` })).toMatchObject({ ok: true });
    const reveal1 = await revealP;
    expect(reveal1.correctOptionId).toBe('truth');
    // Authors unmasked at reveal.
    const truthRevealed = reveal1.options.find((o) => o.id === 'truth');
    expect(truthRevealed.authorId).toBeNull();
    const deltas = Object.fromEntries(reveal1.deltas.map((d) => [d.userId, d]));
    // host: +100 truth, +50 fooled p2 = 150. p2: +50 fooled p3 = 50. p3: 0.
    expect(deltas[hostId].delta).toBe(150);
    expect(deltas[p2Id].delta).toBe(50);
    expect(deltas[p3Id].delta).toBe(0);
    expect(deltas[hostId].votedTruth).toBe(true);

    // ---- round 2: power-ups ----
    const round2P = once(sHost, 'bluff:round');
    await round2P;
    // Host arms Double Agent, then submits.
    expect(await emitAck(sHost, 'bluff:powerup', { type: 'double_agent' })).toMatchObject({ ok: true, armed: true });
    // Double-use rejected.
    const dbl2 = await emitAck(sHost, 'bluff:powerup', { type: 'double_agent' });
    expect(dbl2.ok).toBe(false);
    expect(dbl2.error.code).toBe('BLUFF_POWERUP_SPENT');
    expect(await emitAck(sHost, 'bluff:fake', { text: 'HostFake2' })).toMatchObject({ ok: true });
    expect(await emitAck(s2, 'bluff:fake', { text: 'P2Fake2' })).toMatchObject({ ok: true });
    // p3 steals p2's fake with Swap.
    const swapRes = await emitAck(s3, 'bluff:powerup', { type: 'swap', targetUserId: p2Id });
    expect(swapRes).toMatchObject({ ok: true, stolen: true });
    // p3's fake submit is implicit via swap; still needs no separate submit.
    const vote2P = once(sHost, 'bluff:vote');
    // All fakes are in (host, p2, p3-via-swap) -> vote phase begins.
    const vote2 = await vote2P;
    expect(vote2.options).toHaveLength(4);

    // p2 uses Detective -> private elimination of one wrong option.
    const detP = once(s2, 'bluff:powerup_result');
    expect(await emitAck(s2, 'bluff:powerup', { type: 'detective' })).toMatchObject({ ok: true, used: true });
    const det = await detP;
    expect(det.type).toBe('detective');
    expect(det.eliminatedOptionId).not.toBe('truth');
    expect(det.eliminatedOptionId).not.toBe(`fake:${p2Id}`);

    // Voting the eliminated option is rejected.
    const elimVote = await emitAck(s2, 'bluff:vote', { optionId: det.eliminatedOptionId });
    expect(elimVote.ok).toBe(false);
    expect(elimVote.error.code).toBe('BLUFF_ELIMINATED');

    // Votes: everyone fooled by host's double-agent fake (unless Detective
    // happened to eliminate it — then p2 votes truth instead).
    const reveal2P = once(sHost, 'bluff:reveal');
    expect(await emitAck(sHost, 'bluff:vote', { optionId: 'truth' })).toMatchObject({ ok: true });
    const hostFakeEliminated = det.eliminatedOptionId === `fake:${hostId}`;
    expect(await emitAck(s2, 'bluff:vote', { optionId: hostFakeEliminated ? 'truth' : `fake:${hostId}` })).toMatchObject({ ok: true });
    expect(await emitAck(s3, 'bluff:vote', { optionId: `fake:${hostId}` })).toMatchObject({ ok: true });
    const reveal2 = await reveal2P;
    const d2 = Object.fromEntries(reveal2.deltas.map((d) => [d.userId, d]));
    // host: +100 truth + streak bonus +25 (2nd consecutive truth),
    //   + fooled x 50 x2 (double agent). s3 always fooled; s2 fooled unless
    //   Detective eliminated the host's fake.
    const expectedFooled = hostFakeEliminated ? 1 : 2;
    expect(d2[hostId].fooled).toBe(expectedFooled);
    expect(d2[hostId].delta).toBe(125 + expectedFooled * 100);

    // ---- rounds 3-5: quick play-through ----
    let endP = once(sHost, 'bluff:end');
    for (let r = 3; r <= 5; r++) {
      const rp = once(sHost, 'bluff:round');
      await rp;
      const vp = once(sHost, 'bluff:vote');
      await emitAck(sHost, 'bluff:fake', { text: `HF${r}` });
      await emitAck(s2, 'bluff:fake', { text: `2F${r}` });
      await emitAck(s3, 'bluff:fake', { text: `3F${r}` });
      await vp;
      const revP = once(sHost, 'bluff:reveal');
      await emitAck(sHost, 'bluff:vote', { optionId: 'truth' });
      await emitAck(s2, 'bluff:vote', { optionId: 'truth' });
      await emitAck(s3, 'bluff:vote', { optionId: `fake:${hostId}` });
      await revP;
      if (r < 5) endP = once(sHost, 'bluff:end');
    }
    const end = await endP;
    expect(end.reason).toBe('completed');
    expect(end.winner).toBeTruthy();
    expect(end.scores).toHaveLength(3);
    expect(end.scores[0].score).toBeGreaterThan(end.scores[1].score);
    expect(end.titles[hostId]).toBeTruthy();
    expect(end.rewards).toHaveLength(3);
    expect(end.rewards[0]).toHaveProperty('xpEarned');

    // GameResult docs persisted with mode 'bluff'.
    const results = await GameResult.find({ mode: 'bluff' });
    expect(results.length).toBe(3);

    for (const c of [sHost, s2, s3]) c.disconnect();
    clients = clients.filter((c) => c.connected);
  });
});
