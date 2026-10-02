'use strict';

const { request, registerUser } = require('./helpers');
const { app } = require('./helpers');

function packQuestions(n, answerIndex = 0) {
  return Array.from({ length: n }, (_, i) => ({
    question: `Pack question ${i}?`,
    options: ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
    answerIndex: (answerIndex + i) % 4,
    explanation: `why ${i}`,
  }));
}

function packPayload(overrides = {}) {
  const tag = `${Date.now() % 100000}${Math.floor(Math.random() * 1000)}`;
  return {
    title: `Pk${tag}`,
    description: 'A community pack for testing',
    label: 'Test Lab',
    mode: 'quiz',
    questions: packQuestions(5),
    ...overrides,
  };
}

const auth = (token) => ({ Authorization: `Bearer ${token}` });

// NOTE: tests/setup.js wipes every collection afterEach, so each test
// registers its own users and builds its own pack.
async function setupDraft(overrides = {}) {
  const n = `${Date.now() % 100000}${Math.floor(Math.random() * 10000)}`;
  const author = await registerUser({ username: `pka${n}`.slice(0, 20), email: `pka${n}@example.com` });
  const stranger = await registerUser({ username: `pks${n}`.slice(0, 20), email: `pks${n}@example.com` });
  const res = await request(app)
    .post('/api/packs')
    .set(auth(author.token))
    .send(packPayload(overrides));
  expect(res.status).toBe(201);
  return { author, stranger, packId: res.body.id };
}

describe('game packs', () => {
  test('create draft pack with valid questions', async () => {
    const { author, packId } = await setupDraft();
    const res = await request(app).get(`/api/packs/${packId}`).set(auth(author.token));
    expect(res.status).toBe(200);
    expect(res.body.slug).toMatch(/^[a-z0-9-]+$/);
    expect(res.body.questions).toHaveLength(5);
    // Author sees answers on their own draft.
    expect(res.body.questions[0]).toHaveProperty('answerIndex');
  });

  test('create rejects too few questions', async () => {
    const n = `${Date.now() % 100000}`;
    const author = await registerUser({ username: `pkb${n}`.slice(0, 20), email: `pkb${n}@example.com` });
    const res = await request(app)
      .post('/api/packs')
      .set(auth(author.token))
      .send(packPayload({ questions: packQuestions(3) }));
    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('create rejects bad answerIndex', async () => {
    const n = `${Date.now() % 100000}`;
    const author = await registerUser({ username: `pkc${n}`.slice(0, 20), email: `pkc${n}@example.com` });
    const res = await request(app)
      .post('/api/packs')
      .set(auth(author.token))
      .send(packPayload({ questions: packQuestions(5).map((q, i) => (i === 0 ? { ...q, answerIndex: 7 } : q)) }));
    expect(res.status).toBe(422);
  });

  test('draft is invisible to strangers', async () => {
    const { packId } = await setupDraft();
    const res = await request(app).get(`/api/packs/${packId}`);
    expect(res.status).toBe(404);
  });

  test('stranger cannot publish my draft', async () => {
    const { stranger, packId } = await setupDraft();
    const res = await request(app)
      .post(`/api/packs/${packId}/publish`)
      .set(auth(stranger.token));
    expect(res.status).toBe(403);
  });

  test('publish -> browse list shows card without answers', async () => {
    const { author, packId } = await setupDraft();
    const pub = await request(app).post(`/api/packs/${packId}/publish`).set(auth(author.token));
    expect(pub.status).toBe(200);

    const list = await request(app).get('/api/packs?sort=newest&limit=10');
    expect(list.status).toBe(200);
    const found = list.body.packs.find((p) => p.id === packId);
    expect(found).toBeTruthy();
    expect(found.questionCount).toBe(5);
    expect(found).not.toHaveProperty('questions');

    const detail = await request(app).get(`/api/packs/${packId}`);
    expect(detail.status).toBe(200);
    // Public detail hides answers.
    expect(detail.body.questions[0]).not.toHaveProperty('answerIndex');
  });

  test('editing a published pack is rejected until unpublished', async () => {
    const { author, packId } = await setupDraft();
    await request(app).post(`/api/packs/${packId}/publish`).set(auth(author.token));
    const res = await request(app)
      .put(`/api/packs/${packId}`)
      .set(auth(author.token))
      .send({ title: 'New title attempt' });
    expect(res.status).toBe(409);
  });

  test('install bumps counter and returns answers for offline play', async () => {
    const { stranger, author, packId } = await setupDraft();
    await request(app).post(`/api/packs/${packId}/publish`).set(auth(author.token));
    const before = await request(app).get(`/api/packs/${packId}`);
    const res = await request(app).post(`/api/packs/${packId}/install`).set(auth(stranger.token));
    expect(res.status).toBe(200);
    expect(res.body.installs).toBe(before.body.installs + 1);
    expect(res.body.questions[0]).toHaveProperty('answerIndex');
  });

  test('mine lists my packs with status', async () => {
    const { author, packId } = await setupDraft();
    await request(app).post(`/api/packs/${packId}/publish`).set(auth(author.token));
    const res = await request(app).get('/api/packs/mine').set(auth(author.token));
    expect(res.status).toBe(200);
    const found = res.body.packs.find((p) => p.id === packId);
    expect(found.status).toBe('published');
  });

  test('unpublish then edit then delete', async () => {
    const { author, packId } = await setupDraft();
    await request(app).post(`/api/packs/${packId}/publish`).set(auth(author.token));
    const unpub = await request(app).post(`/api/packs/${packId}/unpublish`).set(auth(author.token));
    expect(unpub.status).toBe(200);

    const upd = await request(app)
      .put(`/api/packs/${packId}`)
      .set(auth(author.token))
      .send({ title: `Rn${Date.now() % 100000}` });
    expect(upd.status).toBe(200);
    expect(upd.body.version).toBe(2);

    const del = await request(app).delete(`/api/packs/${packId}`).set(auth(author.token));
    expect(del.status).toBe(200);
    const gone = await request(app).get(`/api/packs/${packId}`).set(auth(author.token));
    expect(gone.status).toBe(404);
  });

  test('bluff-mode pack validates', async () => {
    const { author, packId } = await setupDraft({ mode: 'bluff' });
    const res = await request(app).get(`/api/packs/${packId}`).set(auth(author.token));
    expect(res.body.mode).toBe('bluff');
  });
});
