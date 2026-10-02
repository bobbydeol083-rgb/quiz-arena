'use strict';

const http = require('http');
const { Server } = require('socket.io');
const { io: ioClient } = require('socket.io-client');
const { request, registerUser } = require('./helpers');
const createApp = require('../src/app');
const initSocket = require('../src/socket');
const Category = require('../src/models/Category');
const Question = require('../src/models/Question');
const GameResult = require('../src/models/GameResult');
const User = require('../src/models/User');

function once(socket, event, timeoutMs = 10000) {
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

describe('socket matchmaking smoke', () => {
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
  });

  beforeEach(async () => {
    const cat = await Category.create({ name: 'SockCat', icon: '🔌', color: '#abcdef', description: 'socket test' });
    for (let i = 0; i < 12; i++) {
      await Question.create({
        category: cat._id,
        difficulty: 'easy',
        question: `Socket question ${i}?`,
        options: ['A', 'B', 'C', 'D'],
        answerIndex: i % 4,
        explanation: 'sock',
      });
    }
    global.__sockCatId = String(cat._id);
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

  test('unauthenticated sockets only receive errors', async () => {
    const s = connect();
    await once(s, 'connect');
    const errP = once(s, 'error');
    s.emit('matchmaking:join', { category: 'any' });
    const err = await errP;
    expect(err.code).toBe('UNAUTHENTICATED');
  });

  test('two players matchmake, play, and finish with rewards', async () => {
    const p1 = await registerUser({ username: 'sockp1', email: 'sockp1@example.com' });
    const p2 = await registerUser({ username: 'sockp2', email: 'sockp2@example.com' });

    const s1 = connect();
    const s2 = connect();
    await Promise.all([once(s1, 'connect'), once(s2, 'connect')]);

    const a1 = await emitAck(s1, 'authenticate', { token: p1.token });
    const a2 = await emitAck(s2, 'authenticate', { token: p2.token });
    expect(a1.ok).toBe(true);
    expect(a2.ok).toBe(true);

    // Presence flipped on.
    const db1 = await User.findById(p1.user.id);
    expect(db1.online).toBe(true);

    // Listen BEFORE joining to avoid races.
    const found1 = once(s1, 'match:found');
    const found2 = once(s2, 'match:found');
    const start1 = once(s1, 'game:start');
    const start2 = once(s2, 'game:start');

    s1.emit('matchmaking:join', { category: global.__sockCatId });
    s2.emit('matchmaking:join', { category: global.__sockCatId });

    const m1 = await found1;
    const m2 = await found2;
    expect(m1.opponent.username).toBe('sockp2');
    expect(m2.opponent.username).toBe('sockp1');
    expect(m1.roomId).toBe(m2.roomId);

    const g1 = await start1;
    const g2 = await start2;
    expect(g1.questions).toHaveLength(10);
    expect(g2.questions).toHaveLength(10);
    for (const q of g1.questions) {
      expect(q).not.toHaveProperty('answerIndex');
      expect(q.options).toHaveLength(4);
    }

    // Answer everything correctly, as fast as possible.
    const dbQuestions = await Question.find({ category: global.__sockCatId });
    const answerOf = new Map(dbQuestions.map((q) => [String(q._id), q.answerIndex]));
    const endP = once(s1, 'game:end', 20000);

    for (const q of g1.questions) {
      const r1 = await emitAck(s1, 'game:answer', { questionId: q.id, selectedIndex: answerOf.get(q.id) });
      expect(r1.ok).toBe(true);
      expect(r1.correct).toBe(true);
      const r2 = await emitAck(s2, 'game:answer', { questionId: q.id, selectedIndex: answerOf.get(q.id) });
      expect(r2.ok).toBe(true);
    }

    const end = await endP;
    expect(end.reason).toBe('completed');
    expect(end.scores).toHaveLength(2);
    expect(end.winner).toBeDefined();
    expect(end.rewards).toHaveLength(2);
    for (const r of end.rewards) {
      expect(r.xpEarned).toBeGreaterThan(0);
      expect(r.newBadges).toContain('first_blood');
    }

    // Persisted.
    const results = await GameResult.find({ mode: 'duel' });
    expect(results).toHaveLength(2);
    expect(results.every((r) => r.total === 10 && r.correct === 10)).toBe(true);

    // Request (supertest) still works alongside sockets.
    const { app } = require('./helpers');
    const me = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${p1.token}`);
    expect(me.status).toBe(200);
  });

  test('duel invite → accept starts a game', async () => {
    const p1 = await registerUser({ username: 'duel1', email: 'duel1@example.com' });
    const p2 = await registerUser({ username: 'duel2', email: 'duel2@example.com' });

    const s1 = connect();
    const s2 = connect();
    await Promise.all([once(s1, 'connect'), once(s2, 'connect')]);
    await emitAck(s1, 'authenticate', { token: p1.token });
    await emitAck(s2, 'authenticate', { token: p2.token });

    const invitedP = once(s2, 'duel:invited');
    const inviteAck = await emitAck(s1, 'duel:invite', { toUserId: p2.user.id, category: global.__sockCatId });
    expect(inviteAck.ok).toBe(true);
    const invited = await invitedP;
    expect(invited.from.username).toBe('duel1');
    expect(invited.inviteId).toBe(inviteAck.inviteId);

    const acceptedP = once(s1, 'duel:accepted');
    const startP = once(s2, 'game:start');
    const acceptAck = await emitAck(s2, 'duel:accept', { inviteId: invited.inviteId });
    expect(acceptAck.ok).toBe(true);

    const accepted = await acceptedP;
    expect(accepted.roomId).toBe(acceptAck.roomId);
    const started = await startP;
    expect(started.questions).toHaveLength(10);
  }, 20000);

  test('game:answer accepts -1 (timeout) and the game still completes', async () => {
    const p1 = await registerUser({ username: 'timeo1', email: 'timeo1@example.com' });
    const p2 = await registerUser({ username: 'timeo2', email: 'timeo2@example.com' });

    const s1 = connect();
    const s2 = connect();
    await Promise.all([once(s1, 'connect'), once(s2, 'connect')]);
    await emitAck(s1, 'authenticate', { token: p1.token });
    await emitAck(s2, 'authenticate', { token: p2.token });

    const start1 = once(s1, 'game:start');
    const start2 = once(s2, 'game:start');
    s1.emit('matchmaking:join', { category: global.__sockCatId });
    s2.emit('matchmaking:join', { category: global.__sockCatId });
    const g1 = await start1;
    await start2;

    const endP = once(s1, 'game:end', 20000);
    const dbQuestions = await Question.find({ category: global.__sockCatId });
    const answerOf = new Map(dbQuestions.map((q) => [String(q._id), q.answerIndex]));

    for (const q of g1.questions) {
      // p1 times out on every question; p2 answers correctly.
      const r1 = await emitAck(s1, 'game:answer', { questionId: q.id, selectedIndex: -1 });
      expect(r1.ok).toBe(true);
      expect(r1.correct).toBe(false);
      const r2 = await emitAck(s2, 'game:answer', { questionId: q.id, selectedIndex: answerOf.get(q.id) });
      expect(r2.ok).toBe(true);
    }

    const end = await endP;
    expect(end.reason).toBe('completed');
    const s1Score = end.scores.find((s) => s.userId === p1.user.id);
    const s2Score = end.scores.find((s) => s.userId === p2.user.id);
    expect(s1Score.correct).toBe(0);
    expect(s1Score.answered).toBe(10);
    expect(s2Score.correct).toBe(10);
    expect(end.winner.userId).toBe(p2.user.id);
  }, 20000);

  test('room:leave mid-duel ends the game by forfeit for the remaining player', async () => {
    const p1 = await registerUser({ username: 'quit1', email: 'quit1@example.com' });
    const p2 = await registerUser({ username: 'quit2', email: 'quit2@example.com' });

    const s1 = connect();
    const s2 = connect();
    await Promise.all([once(s1, 'connect'), once(s2, 'connect')]);
    await emitAck(s1, 'authenticate', { token: p1.token });
    await emitAck(s2, 'authenticate', { token: p2.token });

    const start1 = once(s1, 'game:start');
    s1.emit('matchmaking:join', { category: global.__sockCatId });
    s2.emit('matchmaking:join', { category: global.__sockCatId });
    await start1;

    const endP = once(s2, 'game:end', 20000);
    const leaveAck = await emitAck(s1, 'room:leave', {});
    expect(leaveAck.ok).toBe(true);

    const end = await endP;
    expect(end.reason).toBe('forfeit');
    expect(end.winner.userId).toBe(p2.user.id);
    expect(end.scores).toHaveLength(1);
  }, 20000);
});
