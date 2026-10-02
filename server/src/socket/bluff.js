'use strict';

// Bluff & Brain — a party game where lying is part of the game.
//
// Round flow (server-authoritative):
//   1. WRITE phase  — server sends the question (never the answer). Every
//      player secretly submits one believable fake answer.
//   2. VOTE phase   — fakes are shuffled together with the real answer
//      (authorship hidden). Players vote for the option they think is true.
//      You cannot vote for your own fake.
//   3. REVEAL phase — authors are unmasked, points are awarded:
//        +100 for picking the truth
//        +50  per player fooled by your fake (x2 with Double Agent)
//        +25  streak bonus per consecutive truth-pick beyond the first
//      Then the next round begins.
//
// Power-ups (one use each per game):
//   detective    (vote phase)  — eliminate one wrong option, privately
//   double_agent (write phase) — your fake pays double per fooled player
//   speed_run    (write phase) — fake written within 5s of the phase start:
//                                all your round points x2
//   swap         (write phase) — steal another player's submitted fake text

const User = require('../models/User');
const Room = require('../models/Room');
const GameResult = require('../models/GameResult');
const gamification = require('../utils/gamification');
const logger = require('../utils/logger');

const BLUFF_ROUNDS = 5;
// Phase timers are env-overridable for tests; production defaults unchanged.
const WRITE_MS = Number(process.env.BLUFF_WRITE_MS) || 30000;
const VOTE_MS = Number(process.env.BLUFF_VOTE_MS) || 20000;
const REVEAL_MS = Number(process.env.BLUFF_REVEAL_MS) || 6000;
const MAX_FAKE_LEN = 120;
const SPEED_RUN_WINDOW_MS = 5000;

const POWERUP_TYPES = ['detective', 'double_agent', 'speed_run', 'swap'];

function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function bluffScoresPayload(game) {
  return game.players.map((uid) => ({ userId: String(uid), ...(game.scores[uid] || { score: 0, truths: 0, fooled: 0 }) }));
}

function createBluffEngine(ctx) {
  const { io, userSockets, authed, sockError, sockOk, publicPlayer, joinRoomSocket, dealQuestions } = ctx;
  const bluffGames = new Map(); // roomCode -> bluff game state

  const socketOf = (userId) => {
    const sid = userSockets.get(String(userId));
    return sid ? io.sockets.sockets.get(sid) : null;
  };

  const emitTo = (code, event, payload) => io.to(`room:${code}`).emit(event, payload);

  // ---- lifecycle ---------------------------------------------------------

  async function beginBluffGame({ code, roomId, categoryId, playerIds }) {
    const questions = await dealQuestions(categoryId, BLUFF_ROUNDS);
    if (questions.length === 0) throw new Error('No questions available for this category');

    const game = {
      code,
      roomId,
      mode: 'bluff',
      categoryId,
      questions,
      players: playerIds.map(String),
      round: 0,
      phase: 'lobby',
      fakes: {}, // userId -> { text, submittedAt, doubleAgent, speedRun }
      votes: {}, // userId -> optionId
      options: [], // [{ id, text, authorId|null }]
      scores: {},
      powerups: {}, // userId -> { detective:1, double_agent:1, speed_run:1, swap:1 }
      eliminated: {}, // userId -> Set(optionId) — detective eliminations
      writeStartedAt: 0,
      timer: null,
      startedAt: Date.now(),
    };
    for (const pid of game.players) {
      game.scores[pid] = { score: 0, truths: 0, fooled: 0, truthStreak: 0, bestTruthStreak: 0 };
      game.powerups[pid] = { detective: 1, double_agent: 1, speed_run: 1, swap: 1 };
      game.eliminated[pid] = new Set();
    }
    bluffGames.set(code, game);
    for (const pid of game.players) joinRoomSocket(io, pid, code);

    emitTo(code, 'bluff:start', {
      roomId: code,
      totalRounds: questions.length,
      writeTimeMs: WRITE_MS,
      voteTimeMs: VOTE_MS,
      players: game.players,
    });
    startRound(game);
    return game;
  }

  function clearTimer(game) {
    if (game.timer) { clearTimeout(game.timer); game.timer = null; }
  }

  function startRound(game) {
    game.round += 1;
    game.phase = 'write';
    game.fakes = {};
    game.votes = {};
    game.options = [];
    for (const pid of game.players) game.eliminated[pid] = new Set();

    const q = game.questions[game.round - 1];
    game.writeStartedAt = Date.now();
    emitTo(game.code, 'bluff:round', {
      roomId: game.code,
      round: game.round,
      totalRounds: game.questions.length,
      questionId: String(q._id),
      question: q.question,
      writeEndsAt: game.writeStartedAt + WRITE_MS,
    });
    clearTimer(game);
    game.timer = setTimeout(() => closeWrite(game).catch((e) => logger.error('bluff closeWrite error', e)), WRITE_MS);
  }

  async function closeWrite(game) {
    if (game.phase !== 'write') return;
    game.phase = 'vote';

    const q = game.questions[game.round - 1];
    const truthText = q.options[q.answerIndex];
    const opts = [{ id: 'truth', text: truthText, authorId: null }];
    for (const [uid, fake] of Object.entries(game.fakes)) {
      opts.push({ id: `fake:${uid}`, text: fake.text, authorId: uid });
    }
    game.options = shuffle(opts);
    game.voteStartedAt = Date.now();

    emitTo(game.code, 'bluff:vote', {
      roomId: game.code,
      round: game.round,
      options: game.options.map((o) => ({ id: o.id, text: o.text })),
      voteEndsAt: game.voteStartedAt + VOTE_MS,
    });
    clearTimer(game);
    game.timer = setTimeout(() => reveal(game).catch((e) => logger.error('bluff reveal error', e)), VOTE_MS);
  }

  async function reveal(game) {
    if (game.phase !== 'vote') return;
    game.phase = 'reveal';
    clearTimer(game);

    // Tally votes per option.
    const votesPerOption = {};
    for (const oid of game.options.map((o) => o.id)) votesPerOption[oid] = 0;
    for (const [uid, oid] of Object.entries(game.votes)) {
      if (votesPerOption[oid] !== undefined) votesPerOption[oid] += 1;
    }

    const deltas = [];
    for (const pid of game.players) {
      const s = game.scores[pid];
      const voted = game.votes[pid] || null;
      const votedTruth = voted === 'truth';
      const fake = game.fakes[pid];
      let delta = 0;

      if (votedTruth) {
        delta += 100;
        s.truths += 1;
        s.truthStreak += 1;
        s.bestTruthStreak = Math.max(s.bestTruthStreak, s.truthStreak);
        if (s.truthStreak >= 2) delta += 25 * (s.truthStreak - 1); // streak bonus
      } else {
        s.truthStreak = 0;
      }

      const fooled = fake ? (votesPerOption[`fake:${pid}`] || 0) : 0;
      if (fooled > 0) {
        delta += 50 * fooled * (fake.doubleAgent ? 2 : 1);
        s.fooled += fooled;
      }
      if (fake && fake.speedRun && fake.submittedAt - game.writeStartedAt <= SPEED_RUN_WINDOW_MS) {
        delta *= 2;
      }
      s.score += delta;
      deltas.push({ userId: pid, delta, votedTruth, fooled, votedOptionId: voted });
    }

    emitTo(game.code, 'bluff:reveal', {
      roomId: game.code,
      round: game.round,
      correctOptionId: 'truth',
      options: game.options.map((o) => ({ id: o.id, text: o.text, authorId: o.authorId })),
      votes: { ...game.votes },
      deltas,
      scores: bluffScoresPayload(game),
    });

    game.timer = setTimeout(() => {
      if (game.round < game.questions.length) {
        startRound(game);
      } else {
        endBluffGame(game, 'completed').catch((e) => logger.error('bluff endGame error', e));
      }
    }, REVEAL_MS);
  }

  function titleFor(score, rounds) {
    if (score.truths >= rounds && rounds >= 3) return 'Truth Hunter';
    if (score.fooled >= 10) return 'Master Deceiver';
    if (score.fooled >= 4) return 'Rookie Fibber';
    if (score.truths >= Math.ceil(rounds / 2)) return 'Sharp Eye';
    return 'Bluff Rookie';
  }

  async function endBluffGame(game, reason = 'completed') {
    const { code } = game;
    bluffGames.delete(code);
    clearTimer(game);
    game.phase = 'done';

    const standings = bluffScoresPayload(game).sort((a, b) => b.score - a.score || b.truths - a.truths);
    const winnerId = standings.length ? standings[0].userId : null;
    const rewards = [];
    const titles = {};

    for (const st of standings) {
      const user = await User.findById(st.userId);
      if (!user) continue;
      const s = game.scores[st.userId];
      const won = String(winnerId) === String(st.userId);
      titles[st.userId] = titleFor(s, game.questions.length);

      // Feed the shared gamification engine a synthetic grade so XP, coins,
      // streaks and badges stay consistent with every other mode.
      const graded = {
        score: s.score,
        correct: s.truths,
        total: game.questions.length,
        xp: Math.round(s.score / 10) + Math.min(s.bestTruthStreak, 5) * 2,
        avgTimeMs: 0,
      };
      const r = gamification.applyGameResult(user, graded, { mode: 'bluff', duelWin: won, bluffFooled: s.fooled });
      if (won) user.stats.won = (user.stats.won || 0) + 1;
      user.stats.bluffPlayed = (user.stats.bluffPlayed || 0) + 1;
      if (won) user.stats.bluffWon = (user.stats.bluffWon || 0) + 1;
      user.stats.bluffFooledBest = Math.max(user.stats.bluffFooledBest || 0, s.fooled);

      await GameResult.create({
        user: user._id,
        mode: 'bluff',
        category: game.categoryId,
        difficulty: 'mixed',
        score: s.score,
        correct: s.truths,
        total: game.questions.length,
        xpEarned: r.xpEarned,
        coinsEarned: r.coinsEarned,
        durationMs: Math.max(0, Date.now() - game.startedAt),
        won,
      });
      await user.save();
      rewards.push({ userId: String(st.userId), ...r });
    }

    try {
      const room = await Room.findById(game.roomId);
      if (room) { room.status = 'finished'; await room.save(); }
    } catch (e) { logger.error('bluff room finish failed', e); }

    const winnerUser = winnerId ? await User.findById(winnerId).lean() : null;
    emitTo(code, 'bluff:end', {
      roomId: code,
      reason,
      winner: winnerUser ? { userId: String(winnerUser._id), username: winnerUser.username, avatar: winnerUser.avatar } : null,
      scores: standings,
      titles,
      rewards,
    });
    logger.info(`Bluff game ended room=${code} reason=${reason} winner=${winnerId}`);
  }

  async function leaveBluffGame(code, userId) {
    const game = bluffGames.get(code);
    if (!game) return false;
    game.players = game.players.filter((p) => String(p) !== String(userId));
    delete game.scores[userId];
    delete game.fakes[userId];
    delete game.votes[userId];
    delete game.powerups[userId];
    emitTo(code, 'bluff:player_left', { userId: String(userId), scores: bluffScoresPayload(game) });
    if (game.players.length < 2 && game.phase !== 'done') {
      await endBluffGame(game, 'forfeit');
    } else if (game.phase === 'write' && game.players.every((p) => game.fakes[p])) {
      await closeWrite(game);
    } else if (game.phase === 'vote' && game.players.every((p) => game.votes[p])) {
      await reveal(game);
    }
    return true;
  }

  // ---- player actions ------------------------------------------------------

  function registerBluffHandlers(socket) {
    socket.on('bluff:fake', authed(socket, async (payload, ack) => {
      const code = socket.data.roomCode;
      const game = code && bluffGames.get(code);
      const userId = socket.data.userId;
      if (!game || game.phase !== 'write') {
        sockError(socket, ack, 'BLUFF_WRONG_PHASE', 'Not in the write phase');
        return;
      }
      if (!game.players.includes(userId)) {
        sockError(socket, ack, 'FORBIDDEN', 'You are not a player in this game');
        return;
      }
      const text = String(payload.text || '').trim();
      if (!text || text.length > MAX_FAKE_LEN) {
        sockError(socket, ack, 'VALIDATION_ERROR', `Fake answer must be 1–${MAX_FAKE_LEN} characters`);
        return;
      }
      const prev = game.fakes[userId];
      game.fakes[userId] = {
        text,
        submittedAt: Date.now(),
        doubleAgent: !!(prev && prev.doubleAgent) || !!game.fakes[`${userId}:double_agent`],
        speedRun: !!(prev && prev.speedRun) || !!game.fakes[`${userId}:speed_run`],
      };
      delete game.fakes[`${userId}:double_agent`];
      delete game.fakes[`${userId}:speed_run`];
      sockOk(ack, { submitted: true });
      emitTo(code, 'bluff:fakes_in', { roomId: code, round: game.round, count: Object.keys(game.fakes).filter((k) => !k.includes(':')).length, total: game.players.length });
      if (game.players.every((p) => game.fakes[p])) {
        await closeWrite(game);
      }
    }));

    socket.on('bluff:vote', authed(socket, async (payload, ack) => {
      const code = socket.data.roomCode;
      const game = code && bluffGames.get(code);
      const userId = socket.data.userId;
      if (!game || game.phase !== 'vote') {
        sockError(socket, ack, 'BLUFF_WRONG_PHASE', 'Not in the vote phase');
        return;
      }
      if (!game.players.includes(userId)) {
        sockError(socket, ack, 'FORBIDDEN', 'You are not a player in this game');
        return;
      }
      const optionId = String(payload.optionId || '');
      const option = game.options.find((o) => o.id === optionId);
      if (!option) {
        sockError(socket, ack, 'VALIDATION_ERROR', 'Unknown option');
        return;
      }
      if (option.authorId === userId) {
        sockError(socket, ack, 'BLUFF_OWN_FAKE', 'You cannot vote for your own fake');
        return;
      }
      if (game.eliminated[userId].has(optionId)) {
        sockError(socket, ack, 'BLUFF_ELIMINATED', 'Your Detective eliminated that option');
        return;
      }
      game.votes[userId] = optionId;
      sockOk(ack, { voted: true });
      if (game.players.every((p) => game.votes[p])) {
        await reveal(game);
      }
    }));

    socket.on('bluff:powerup', authed(socket, async (payload, ack) => {
      const code = socket.data.roomCode;
      const game = code && bluffGames.get(code);
      const userId = socket.data.userId;
      if (!game || !game.players.includes(userId)) {
        sockError(socket, ack, 'GAME_NOT_FOUND', 'No active bluff game in your room');
        return;
      }
      const type = String(payload.type || '');
      if (!POWERUP_TYPES.includes(type)) {
        sockError(socket, ack, 'VALIDATION_ERROR', `type must be one of: ${POWERUP_TYPES.join(', ')}`);
        return;
      }
      const remaining = game.powerups[userId][type];
      if (!remaining) {
        sockError(socket, ack, 'BLUFF_POWERUP_SPENT', 'Power-up already used');
        return;
      }

      if (type === 'detective') {
        if (game.phase !== 'vote') {
          sockError(socket, ack, 'BLUFF_WRONG_PHASE', 'Detective can only be used during voting');
          return;
        }
        const candidates = game.options.filter(
          (o) => o.id !== 'truth' && o.authorId !== userId && !game.eliminated[userId].has(o.id)
        );
        if (candidates.length === 0) {
          sockError(socket, ack, 'BLUFF_NO_CANDIDATE', 'Nothing left to eliminate');
          return;
        }
        const eliminated = candidates[Math.floor(Math.random() * candidates.length)];
        game.eliminated[userId].add(eliminated.id);
        game.powerups[userId][type] = 0;
        const s = socketOf(userId);
        if (s) s.emit('bluff:powerup_result', { type, round: game.round, eliminatedOptionId: eliminated.id });
        sockOk(ack, { used: true });
        return;
      }

      if (game.phase !== 'write') {
        sockError(socket, ack, 'BLUFF_WRONG_PHASE', 'This power-up can only be used during the write phase');
        return;
      }
      if (type === 'double_agent') {
        const existing = game.fakes[userId];
        if (existing) existing.doubleAgent = true;
        else game.fakes[`${userId}:double_agent`] = true;
        game.powerups[userId][type] = 0;
        sockOk(ack, { used: true, armed: true });
        return;
      }
      if (type === 'speed_run') {
        const existing = game.fakes[userId];
        if (existing) existing.speedRun = true;
        else game.fakes[`${userId}:speed_run`] = true;
        game.powerups[userId][type] = 0;
        sockOk(ack, { used: true, armed: true });
        return;
      }
      // swap — steal another player's submitted fake text
      const targetId = String(payload.targetUserId || '');
      if (!game.players.includes(targetId) || targetId === userId) {
        sockError(socket, ack, 'VALIDATION_ERROR', 'targetUserId must be another player');
        return;
      }
      const targetFake = game.fakes[targetId];
      if (!targetFake || !targetFake.text) {
        sockError(socket, ack, 'BLUFF_SWAP_EMPTY', 'That player has not submitted a fake yet');
        return;
      }
      game.fakes[userId] = { text: targetFake.text, submittedAt: Date.now(), doubleAgent: false, speedRun: false, swappedFrom: targetId };
      game.powerups[userId][type] = 0;
      sockOk(ack, { used: true, stolen: true });
      emitTo(code, 'bluff:fakes_in', { roomId: code, round: game.round, count: Object.keys(game.fakes).filter((k) => !k.includes(':')).length, total: game.players.length });
      if (game.players.every((p) => game.fakes[p])) {
        await closeWrite(game);
      }
    }));
  }

  return { bluffGames, beginBluffGame, endBluffGame, leaveBluffGame, registerBluffHandlers, BLUFF_ROUNDS, WRITE_MS, VOTE_MS };
}

module.exports = { createBluffEngine, BLUFF_ROUNDS, WRITE_MS, VOTE_MS, POWERUP_TYPES };
