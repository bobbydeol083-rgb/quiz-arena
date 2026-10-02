'use strict';

// Realtime layer: presence, matchmaking, duel invites, rooms and live games.
//
// In-memory state (queues, invites, live games) is per-process. For a
// multi-instance production deployment, front this with the socket.io Redis
// adapter and move game state to Redis — see README "Production notes".

const crypto = require('crypto');
const mongoose = require('mongoose');
const User = require('../models/User');
const Room = require('../models/Room');
const Category = require('../models/Category');
const Question = require('../models/Question');
const GameResult = require('../models/GameResult');
const gamification = require('../utils/gamification');
const { verifyToken } = require('../utils/tokens');
const { sanitizeQuestions } = require('../utils/serialize');
const logger = require('../utils/logger');
const { MAX_PLAYERS } = require('../controllers/roomController');
const { createBluffEngine } = require('./bluff');

const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const QUESTIONS_PER_GAME = 10;
const TIME_PER_QUESTION_MS = 15000;
const INVITE_TTL_MS = 60000;

function init(io) {
  // ---- in-memory state -------------------------------------------------
  const userSockets = new Map(); // userId -> socketId
  const queues = new Map(); // queueKey -> [{ userId, socketId }]
  const invites = new Map(); // inviteId -> { from, to, categoryId, timer }
  const games = new Map(); // roomCode -> game state

  // ---- helpers ---------------------------------------------------------
  const sockError = (socket, ack, code, message) => {
    socket.emit('error', { code, message });
    if (typeof ack === 'function') ack({ ok: false, error: { code, message } });
  };
  const sockOk = (ack, data = {}) => {
    if (typeof ack === 'function') ack({ ok: true, ...data });
  };
  const authed = (socket, handler) => async (payload, ack) => {
    if (!socket.data.userId) {
      sockError(socket, ack, 'UNAUTHENTICATED', 'Emit "authenticate" with a valid access token first');
      return;
    }
    try {
      await handler(payload || {}, ack);
    } catch (err) {
      logger.error('socket handler error', err);
      sockError(socket, ack, 'SERVER_ERROR', 'Something went wrong');
    }
  };
  const isId = (v) => typeof v === 'string' && mongoose.isValidObjectId(v);

  async function resolveCategory(ref) {
    if (!ref || ref === 'any') return null;
    if (isId(ref)) return Category.findById(ref);
    return Category.findOne({ name: new RegExp(`^${String(ref).trim()}$`, 'i') });
  }

  async function generateUniqueCode() {
    for (let i = 0; i < 10; i++) {
      let code = '';
      for (let j = 0; j < 6; j++) code += CODE_ALPHABET[crypto.randomInt(CODE_ALPHABET.length)];
      if (!(await Room.findOne({ code }))) return code;
    }
    throw new Error('Could not generate a unique room code');
  }

  async function dealQuestions(categoryId, count = QUESTIONS_PER_GAME) {
    const pipeline = [];
    if (categoryId) pipeline.push({ $match: { category: new mongoose.Types.ObjectId(categoryId) } });
    pipeline.push({ $sample: { size: count } });
    return Question.aggregate(pipeline);
  }

  function publicPlayer(u) {
    return { id: String(u._id), username: u.username, avatar: u.avatar };
  }

  function joinRoomSocket(ioRef, userId, code) {
    const sid = userSockets.get(String(userId));
    const s = sid && ioRef.sockets.sockets.get(sid);
    if (s) {
      s.join(`room:${code}`);
      s.data.roomCode = code;
    }
    return s;
  }

  function scoresPayload(game) {
    return game.players.map((uid) => ({ userId: String(uid), ...(game.scores[uid] || { score: 0, correct: 0, answered: 0 }) }));
  }

  // Bluff & Brain engine — created after the const helpers above so the
  // context it receives is fully initialized.
  const bluff = createBluffEngine({
    io,
    userSockets,
    authed,
    sockError,
    sockOk,
    publicPlayer,
    joinRoomSocket,
    dealQuestions,
  });

  // ---- game lifecycle ---------------------------------------------------
  async function beginGame(ioRef, { code, roomId, mode, categoryId, playerIds }) {
    const questions = await dealQuestions(categoryId, QUESTIONS_PER_GAME);
    if (questions.length === 0) throw new Error('No questions available for this category');

    const startedAt = Date.now();
    const game = {
      code,
      roomId,
      mode,
      categoryId,
      questions,
      players: playerIds.map(String),
      scores: {},
      answers: {}, // userId -> { questionId: { selectedIndex, correct, timeMs } }
      lastAnswerAt: {},
      startedAt,
      timer: null,
    };
    for (const pid of game.players) {
      game.scores[pid] = { score: 0, correct: 0, answered: 0 };
      game.answers[pid] = {};
    }
    game.timer = setTimeout(() => {
      endGame(ioRef, code, 'timeout').catch((e) => logger.error('endGame timeout error', e));
    }, questions.length * TIME_PER_QUESTION_MS + 10000);
    games.set(code, game);

    for (const pid of game.players) joinRoomSocket(ioRef, pid, code);
    ioRef.to(`room:${code}`).emit('game:start', {
      roomId: code,
      mode,
      questions: sanitizeQuestions(questions),
      questionCount: questions.length,
      timePerQuestionMs: TIME_PER_QUESTION_MS,
    });
    return game;
  }

  async function endGame(ioRef, code, reason = 'completed') {
    const game = games.get(code);
    if (!game) return;
    games.delete(code);
    if (game.timer) clearTimeout(game.timer);
    const now = new Date();

    const standings = scoresPayload(game).sort((a, b) => b.score - a.score || b.correct - a.correct);
    const winnerId = standings.length ? standings[0].userId : null;
    const questionMap = new Map(game.questions.map((q) => [String(q._id), { answerIndex: q.answerIndex }]));
    const rewards = [];

    for (const s of standings) {
      const user = await User.findById(s.userId);
      if (!user) continue;
      // Reuse the single gamification source of truth for XP math.
      const pseudoAnswers = game.questions.map((q) => {
        const a = (game.answers[s.userId] || {})[String(q._id)] || {};
        return { questionId: String(q._id), selectedIndex: a.selectedIndex ?? -1, timeMs: a.timeMs || 0 };
      });
      const streakPre = gamification.nextStreak(user.streak, now);
      const graded = gamification.gradeSubmission({
        answers: pseudoAnswers,
        questionMap,
        difficulty: 'medium',
        streakCount: streakPre.count,
      });
      const duelWin = game.mode === 'duel' && String(winnerId) === String(s.userId);
      const r = gamification.applyGameResult(user, graded, { mode: game.mode, duelWin, now });
      const won = String(winnerId) === String(s.userId);
      if (won) user.stats.won = (user.stats.won || 0) + 1;

      await GameResult.create({
        user: user._id,
        mode: game.mode,
        category: game.categoryId,
        difficulty: 'mixed',
        score: graded.score,
        correct: graded.correct,
        total: game.questions.length,
        xpEarned: r.xpEarned,
        coinsEarned: r.coinsEarned,
        durationMs: Math.max(0, Date.now() - game.startedAt),
        won,
      });
      await user.save();
      rewards.push({ userId: String(s.userId), ...r });
    }

    const room = await Room.findById(game.roomId);
    if (room) {
      room.status = 'finished';
      await room.save();
    }

    const winnerUser = winnerId ? await User.findById(winnerId).lean() : null;
    ioRef.to(`room:${code}`).emit('game:end', {
      roomId: code,
      reason,
      winner: winnerUser ? { userId: String(winnerUser._id), username: winnerUser.username, avatar: winnerUser.avatar } : null,
      scores: standings,
      rewards,
    });
    logger.info(`Game ended room=${code} reason=${reason} winner=${winnerId}`);
  }

  function removeFromQueues(userId) {
    for (const [key, q] of queues) {
      const idx = q.findIndex((e) => e.userId === userId);
      if (idx !== -1) q.splice(idx, 1);
      if (q.length === 0) queues.delete(key);
    }
  }

  function cancelInvitesFor(userId, ioRef) {
    for (const [inviteId, inv] of invites) {
      if (inv.from === userId || inv.to === userId) {
        clearTimeout(inv.timer);
        invites.delete(inviteId);
        ioRef.to(`user:${inv.from}`).emit('duel:expired', { inviteId });
        ioRef.to(`user:${inv.to}`).emit('duel:expired', { inviteId });
      }
    }
  }

  // Remove a socket from its party/duel room and any live game in it.
  // If a live game drops to one (or zero) players left, end it immediately
  // so the remaining player wins by forfeit instead of stalling on the timer.
  async function leaveRoomGame(ioRef, socket) {
    const userId = socket.data.userId;
    const code = socket.data.roomCode;
    if (!userId || !code) return;
    socket.leave(`room:${code}`);
    socket.data.roomCode = null;
    try {
      // Atomic $pull: concurrent disconnects must not clobber each other
      // with load-filter-save races (Mongoose VersionError).
      await Room.updateOne({ code }, { $pull: { players: new mongoose.Types.ObjectId(userId) } });
      const room = await Room.findOne({ code });
      if (room) {
        const players = await User.find({ _id: { $in: room.players } }).lean();
        ioRef.to(`room:${code}`).emit('room:update', { roomId: code, players: players.map(publicPlayer) });
      }
    } catch (e) {
      logger.error('leaveRoomGame room update failed', e);
    }
    const game = games.get(code);
    if (!game) {
      // Not a classic game — maybe a Bluff & Brain table.
      await bluff.leaveBluffGame(code, userId).catch((e) => logger.error('leaveRoomGame bluff failed', e));
      return;
    }
    game.players = game.players.filter((p) => String(p) !== String(userId));
    delete game.scores[userId];
    delete game.answers[userId];
    delete game.lastAnswerAt[userId];
    ioRef.to(`room:${code}`).emit('player:left', { userId: String(userId) });
    if (game.players.length <= 1) {
      await endGame(ioRef, code, 'forfeit').catch((e) => logger.error('leaveRoomGame endGame failed', e));
    } else {
      ioRef.to(`room:${code}`).emit('game:score', { roomId: code, scores: scoresPayload(game) });
    }
  }

  // ---- connection --------------------------------------------------------
  io.on('connection', (socket) => {
    logger.debug(`socket connected ${socket.id}`);

    socket.on('authenticate', async (payload = {}, ack) => {
      try {
        const decoded = verifyToken(payload.token);
        if (decoded.type !== 'access') throw new Error('not an access token');
        const user = await User.findById(decoded.sub);
        if (!user) throw new Error('user not found');
        socket.data.userId = String(user._id);
        userSockets.set(socket.data.userId, socket.id);
        socket.join(`user:${socket.data.userId}`);
        user.online = true;
        user.lastSeen = new Date();
        await user.save();
        sockOk(ack, { user: publicPlayer(user) });
        socket.emit('authenticated', { user: publicPlayer(user) });
      } catch {
        sockError(socket, ack, 'UNAUTHENTICATED', 'Invalid or expired access token');
      }
    });

    socket.on('disconnect', async () => {
      const userId = socket.data.userId;
      if (!userId) return;
      if (userSockets.get(userId) === socket.id) userSockets.delete(userId);
      removeFromQueues(userId);
      cancelInvitesFor(userId, io);
      try {
        const user = await User.findById(userId);
        if (user) {
          user.online = false;
          user.lastSeen = new Date();
          await user.save();
        }
      } catch (e) {
        logger.error('disconnect presence update failed', e);
      }
      const roomCode = socket.data.roomCode;
      if (roomCode) {
        await leaveRoomGame(io, socket).catch((e) => logger.error('disconnect leaveRoomGame failed', e));
      }
      logger.debug(`socket disconnected ${socket.id} user=${userId}`);
    });

    // ---- matchmaking ------------------------------------------------------
    socket.on('matchmaking:join', authed(socket, async (payload, ack) => {
      const categoryDoc = await resolveCategory(payload.category);
      if (payload.category && payload.category !== 'any' && !categoryDoc) {
        sockError(socket, ack, 'CATEGORY_NOT_FOUND', 'Category not found');
        return;
      }
      const key = categoryDoc ? String(categoryDoc._id) : 'any';
      if (!queues.has(key)) queues.set(key, []);
      const q = queues.get(key);
      if (q.some((e) => e.userId === socket.data.userId)) {
        sockOk(ack, { queued: true, position: q.findIndex((e) => e.userId === socket.data.userId) + 1 });
        return;
      }
      q.push({ userId: socket.data.userId, socketId: socket.id });
      socket.emit('matchmaking:queued', { category: key, position: q.length });
      sockOk(ack, { queued: true, position: q.length });

      if (q.length >= 2) {
        const a = q.shift();
        const b = q.shift();
        const code = await generateUniqueCode();
        const room = await Room.create({
          code,
          host: a.userId,
          players: [a.userId, b.userId],
          mode: 'duel',
          category: categoryDoc ? categoryDoc._id : null,
          status: 'playing',
        });
        const users = await User.find({ _id: { $in: [a.userId, b.userId] } }).lean();
        const byId = new Map(users.map((u) => [String(u._id), u]));
        const sa = io.sockets.sockets.get(a.socketId);
        const sb = io.sockets.sockets.get(b.socketId);
        if (sa && byId.get(b.userId)) sa.emit('match:found', { roomId: code, opponent: publicPlayer(byId.get(b.userId)) });
        if (sb && byId.get(a.userId)) sb.emit('match:found', { roomId: code, opponent: publicPlayer(byId.get(a.userId)) });
        await beginGame(io, { code, roomId: room._id, mode: 'duel', categoryId: categoryDoc ? categoryDoc._id : null, playerIds: [a.userId, b.userId] });
      }
    }));

    socket.on('matchmaking:leave', authed(socket, async (payload, ack) => {
      removeFromQueues(socket.data.userId);
      sockOk(ack, { queued: false });
      socket.emit('matchmaking:left', {});
    }));

    // ---- duel invites ------------------------------------------------------
    socket.on('duel:invite', authed(socket, async (payload, ack) => {
      const toUserId = payload.toUserId;
      if (!isId(toUserId)) {
        sockError(socket, ack, 'VALIDATION_ERROR', 'toUserId must be a valid user id');
        return;
      }
      if (toUserId === socket.data.userId) {
        sockError(socket, ack, 'VALIDATION_ERROR', 'You cannot duel yourself');
        return;
      }
      const target = await User.findById(toUserId).lean();
      if (!target) {
        sockError(socket, ack, 'USER_NOT_FOUND', 'Target user not found');
        return;
      }
      const categoryDoc = await resolveCategory(payload.category);
      if (payload.category && !categoryDoc) {
        sockError(socket, ack, 'CATEGORY_NOT_FOUND', 'Category not found');
        return;
      }
      const inviteId = crypto.randomBytes(8).toString('hex');
      const fromUser = await User.findById(socket.data.userId).lean();
      const timer = setTimeout(() => {
        invites.delete(inviteId);
        io.to(`user:${socket.data.userId}`).emit('duel:expired', { inviteId });
        io.to(`user:${toUserId}`).emit('duel:expired', { inviteId });
      }, INVITE_TTL_MS);
      invites.set(inviteId, { from: socket.data.userId, to: String(toUserId), categoryId: categoryDoc ? String(categoryDoc._id) : null, timer });
      io.to(`user:${toUserId}`).emit('duel:invited', {
        inviteId,
        from: publicPlayer(fromUser),
        category: categoryDoc ? { id: String(categoryDoc._id), name: categoryDoc.name, icon: categoryDoc.icon, color: categoryDoc.color } : null,
      });
      sockOk(ack, { inviteId });
    }));

    socket.on('duel:accept', authed(socket, async (payload, ack) => {
      const inv = invites.get(payload.inviteId);
      if (!inv || inv.to !== socket.data.userId) {
        sockError(socket, ack, 'INVITE_NOT_FOUND', 'Invite not found or expired');
        return;
      }
      clearTimeout(inv.timer);
      invites.delete(payload.inviteId);
      const code = await generateUniqueCode();
      const room = await Room.create({
        code,
        host: inv.from,
        players: [inv.from, inv.to],
        mode: 'duel',
        category: inv.categoryId,
        status: 'playing',
      });
      io.to(`user:${inv.from}`).emit('duel:accepted', { inviteId: payload.inviteId, roomId: code });
      sockOk(ack, { roomId: code });
      await beginGame(io, { code, roomId: room._id, mode: 'duel', categoryId: inv.categoryId, playerIds: [inv.from, inv.to] });
    }));

    socket.on('duel:decline', authed(socket, async (payload, ack) => {
      const inv = invites.get(payload.inviteId);
      if (!inv || inv.to !== socket.data.userId) {
        sockError(socket, ack, 'INVITE_NOT_FOUND', 'Invite not found or expired');
        return;
      }
      clearTimeout(inv.timer);
      invites.delete(payload.inviteId);
      io.to(`user:${inv.from}`).emit('duel:declined', { inviteId: payload.inviteId, by: socket.data.userId });
      sockOk(ack, { declined: true });
    }));

    // ---- rooms --------------------------------------------------------------
    socket.on('room:create', authed(socket, async (payload, ack) => {
      const mode = ['duel', 'bluff'].includes(payload.mode) ? payload.mode : 'room';
      const categoryDoc = await resolveCategory(payload.category);
      if (payload.category && !categoryDoc) {
        sockError(socket, ack, 'CATEGORY_NOT_FOUND', 'Category not found');
        return;
      }
      const code = await generateUniqueCode();
      await Room.create({
        code,
        host: socket.data.userId,
        players: [socket.data.userId],
        mode,
        category: categoryDoc ? categoryDoc._id : null,
        status: 'waiting',
      });
      socket.join(`room:${code}`);
      socket.data.roomCode = code;
      sockOk(ack, { code });
      socket.emit('room:created', { code });
    }));

    socket.on('room:join', authed(socket, async (payload, ack) => {
      const code = String(payload.code || '').toUpperCase();
      const room = await Room.findOne({ code }).populate('players', 'username avatar');
      if (!room) {
        sockError(socket, ack, 'ROOM_NOT_FOUND', 'Room not found');
        return;
      }
      if (room.status !== 'waiting') {
        sockError(socket, ack, 'ROOM_CLOSED', 'Room is no longer accepting players');
        return;
      }
      if (!room.players.some((p) => String(p._id) === socket.data.userId)) {
        if (room.players.length >= MAX_PLAYERS) {
          sockError(socket, ack, 'ROOM_FULL', 'Room is full');
          return;
        }
        room.players.push(socket.data.userId);
        await room.save();
      }
      socket.join(`room:${code}`);
      socket.data.roomCode = code;
      const players = await User.find({ _id: { $in: room.players } }).lean();
      io.to(`room:${code}`).emit('room:update', { roomId: code, players: players.map(publicPlayer) });
      sockOk(ack, { code });
    }));

    socket.on('room:leave', authed(socket, async (payload, ack) => {
      await leaveRoomGame(io, socket);
      sockOk(ack, { left: true });
    }));

    socket.on('room:start', authed(socket, async (payload, ack) => {
      const code = socket.data.roomCode;
      const room = code ? await Room.findOne({ code }) : null;
      if (!room) {
        sockError(socket, ack, 'ROOM_NOT_FOUND', 'You are not in a room');
        return;
      }
      if (String(room.host) !== socket.data.userId) {
        sockError(socket, ack, 'FORBIDDEN', 'Only the host can start the room');
        return;
      }
      if (room.status !== 'waiting') {
        sockError(socket, ack, 'ROOM_CLOSED', 'Room already started');
        return;
      }
      room.status = 'playing';
      await room.save();
      sockOk(ack, { started: true });
      if (room.mode === 'bluff') {
        await bluff.beginBluffGame({
          code,
          roomId: room._id,
          categoryId: room.category,
          playerIds: room.players.map(String),
        });
        return;
      }
      await beginGame(io, {
        code,
        roomId: room._id,
        mode: room.mode,
        categoryId: room.category,
        playerIds: room.players.map(String),
      });
    }));

    // ---- live answers --------------------------------------------------------
    socket.on('game:answer', authed(socket, async (payload, ack) => {
      const code = socket.data.roomCode;
      const game = code && games.get(code);
      if (!game) {
        sockError(socket, ack, 'GAME_NOT_FOUND', 'No active game in your room');
        return;
      }
      const userId = socket.data.userId;
      if (!game.players.includes(userId)) {
        sockError(socket, ack, 'FORBIDDEN', 'You are not a player in this game');
        return;
      }
      const qid = String(payload.questionId || '');
      const question = game.questions.find((q) => String(q._id) === qid);
      if (!question) {
        sockError(socket, ack, 'INVALID_QUESTION', 'Question is not part of this game');
        return;
      }
      const selectedIndex = Number(payload.selectedIndex);
      // -1 = the client timed out / skipped: count the question as answered
      // (so the game can finish) without awarding points.
      if (!Number.isInteger(selectedIndex) || selectedIndex < -1 || selectedIndex > 3) {
        sockError(socket, ack, 'VALIDATION_ERROR', 'selectedIndex must be -1–3 (-1 = timed out)');
        return;
      }
      if (game.answers[userId][qid]) {
        sockError(socket, ack, 'ALREADY_ANSWERED', 'You already answered this question');
        return;
      }

      const nowMs = Date.now();
      const timeMs = Math.max(0, nowMs - (game.lastAnswerAt[userId] || game.startedAt));
      game.lastAnswerAt[userId] = nowMs;
      const correct = selectedIndex === question.answerIndex;
      game.answers[userId][qid] = { selectedIndex, correct, timeMs };
      const s = game.scores[userId];
      s.answered += 1;
      if (correct) {
        const timeBonus = Math.round(50 * (1 - Math.min(timeMs, 10000) / 10000));
        s.score += 100 + Math.max(0, timeBonus);
        s.correct += 1;
      }
      sockOk(ack, { correct });
      io.to(`room:${code}`).emit('game:score', { roomId: code, scores: scoresPayload(game) });

      const done = game.players.every((pid) => Object.keys(game.answers[pid]).length >= game.questions.length);
      if (done) {
        await endGame(io, code, 'completed');
      }
    }));

    // Bluff & Brain player actions (write / vote / power-ups).
    bluff.registerBluffHandlers(socket);
  });

  return { userSockets, queues, invites, games, bluffGames: bluff.bluffGames, endGame: (code, reason) => endGame(io, code, reason) };
}

module.exports = init;
