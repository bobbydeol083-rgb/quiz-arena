'use strict';

const { app, request, registerUser } = require('./helpers');
const Category = require('../src/models/Category');
const Question = require('../src/models/Question');
const GameResult = require('../src/models/GameResult');
const User = require('../src/models/User');
const gamification = require('../src/utils/gamification');

async function seedQuiz() {
  const cat = await Category.create({ name: 'TestCat', icon: '🧪', color: '#123456', description: 'test' });
  const docs = [];
  for (let i = 0; i < 5; i++) {
    docs.push(await Question.create({
      category: cat._id,
      difficulty: 'medium',
      question: `Test question ${i}?`,
      options: ['A', 'B', 'C', 'D'],
      answerIndex: i % 4,
      explanation: `Explanation ${i}`,
    }));
  }
  return { cat, docs };
}

describe('quiz submit', () => {
  test('grades server-side, applies gamification, persists result', async () => {
    const { cat, docs } = await seedQuiz();
    const { token, user } = await registerUser({ username: 'quizzer1', email: 'quizzer1@example.com' });

    // 4 correct, 1 wrong
    const answers = docs.map((q, i) => ({
      questionId: String(q._id),
      selectedIndex: i < 4 ? q.answerIndex : (q.answerIndex + 1) % 4,
      timeMs: 2000 + i * 100,
    }));

    const res = await request(app)
      .post('/api/quiz/submit')
      .set('Authorization', `Bearer ${token}`)
      .send({ mode: 'solo', category: String(cat._id), difficulty: 'medium', answers, startedAt: Date.now() - 30000 });

    expect(res.status).toBe(200);
    const body = res.body;
    expect(body.correct).toBe(4);
    expect(body.total).toBe(5);
    expect(body.score).toBeGreaterThan(0);

    // Independent expected-value computation through the same engine.
    const questionMap = new Map(docs.map((q) => [String(q._id), { answerIndex: q.answerIndex }]));
    const graded = gamification.gradeSubmission({ answers, questionMap, difficulty: 'medium', streakCount: 1 });
    expect(body.xpEarned).toBe(graded.xp);
    // coins = 4*2 = 8 (not perfect, no duel win)
    expect(body.coinsEarned).toBe(8);
    expect(body.newBadges).toContain('first_blood');
    expect(body.levelUp).toBe(false);
    expect(body.streak.count).toBe(1);

    // User document updated.
    const dbUser = await User.findById(user.id);
    expect(dbUser.xp).toBe(graded.xp);
    expect(dbUser.coins).toBe(8);
    expect(dbUser.stats.played).toBe(1);
    expect(dbUser.stats.correctAnswers).toBe(4);
    expect(dbUser.stats.totalAnswers).toBe(5);
    expect(dbUser.badges).toContain('first_blood');

    // GameResult persisted.
    const results = await GameResult.find({ user: user.id });
    expect(results).toHaveLength(1);
    expect(results[0]).toMatchObject({
      mode: 'solo',
      correct: 4,
      total: 5,
      xpEarned: graded.xp,
      coinsEarned: 8,
    });
    expect(String(results[0].category)).toBe(String(cat._id));
  });

  test('level-up is reported when crossing a threshold', async () => {
    const { cat, docs } = await seedQuiz();
    const { token, user } = await registerUser({ username: 'levelup1', email: 'levelup1@example.com' });
    await User.findByIdAndUpdate(user.id, { xp: 95 });

    const answers = docs.map((q) => ({ questionId: String(q._id), selectedIndex: q.answerIndex, timeMs: 1000 }));
    const res = await request(app)
      .post('/api/quiz/submit')
      .set('Authorization', `Bearer ${token}`)
      .send({ mode: 'solo', category: String(cat._id), difficulty: 'easy', answers, startedAt: Date.now() - 10000 });

    expect(res.status).toBe(200);
    expect(res.body.levelUp).toBe(true);
    expect(res.body.level).toBe(2);
  });

  test('invalid questionId → 400 INVALID_QUESTION', async () => {
    await seedQuiz();
    const { token } = await registerUser({ username: 'quizzer2', email: 'quizzer2@example.com' });
    const res = await request(app)
      .post('/api/quiz/submit')
      .set('Authorization', `Bearer ${token}`)
      .send({
        mode: 'solo',
        difficulty: 'easy',
        answers: [{ questionId: '507f1f77bcf86cd799439011', selectedIndex: 0, timeMs: 1000 }],
        startedAt: Date.now(),
      });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_QUESTION');
  });

  test('unauthenticated submit → 401', async () => {
    const res = await request(app).post('/api/quiz/submit').send({ mode: 'solo', answers: [] });
    expect(res.status).toBe(401);
  });

  test('GET /api/questions never leaks answerIndex', async () => {
    const { cat } = await seedQuiz();
    const res = await request(app).get(`/api/questions?category=${cat._id}&count=5`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(5);
    for (const q of res.body) {
      expect(q).not.toHaveProperty('answerIndex');
      expect(q.options).toHaveLength(4);
      expect(q).toHaveProperty('explanation');
    }
  });

  test('GET /api/categories returns quizCount', async () => {
    const { cat } = await seedQuiz();
    const res = await request(app).get('/api/categories');
    expect(res.status).toBe(200);
    const entry = res.body.find((c) => c.id === String(cat._id));
    expect(entry).toMatchObject({ name: 'TestCat', quizCount: 5 });
  });

  test('accepts ISO-8601 startedAt (what the Flutter app sends)', async () => {
    const { cat, docs } = await seedQuiz();
    const { token } = await registerUser({ username: 'quizzer_iso', email: 'quizzer_iso@example.com' });
    const answers = docs.map((q) => ({
      questionId: String(q._id),
      selectedIndex: q.answerIndex,
      timeMs: 1500,
    }));
    const res = await request(app)
      .post('/api/quiz/submit')
      .set('Authorization', `Bearer ${token}`)
      .send({
        mode: 'solo',
        category: String(cat._id),
        difficulty: 'medium',
        answers,
        startedAt: new Date(Date.now() - 45000).toISOString(),
      });
    expect(res.status).toBe(200);
    expect(res.body.correct).toBe(5);
    const saved = await GameResult.findOne({ user: (await User.findOne({ email: 'quizzer_iso@example.com' }))._id });
    expect(Number.isFinite(saved.durationMs)).toBe(true);
    expect(saved.durationMs).toBeGreaterThan(0);
  });

  test('accepts selectedIndex -1 (client timeout) without 400', async () => {
    const { cat, docs } = await seedQuiz();
    const { token } = await registerUser({ username: 'quizzer_to', email: 'quizzer_to@example.com' });
    const answers = docs.map((q, i) => ({
      questionId: String(q._id),
      // first two time out, rest correct
      selectedIndex: i < 2 ? -1 : q.answerIndex,
      timeMs: 1500,
    }));
    const res = await request(app)
      .post('/api/quiz/submit')
      .set('Authorization', `Bearer ${token}`)
      .send({ mode: 'blitz', category: String(cat._id), difficulty: 'medium', answers, startedAt: Date.now() - 20000 });
    expect(res.status).toBe(200);
    expect(res.body.correct).toBe(3);
    expect(res.body.total).toBe(5);
  });
});
