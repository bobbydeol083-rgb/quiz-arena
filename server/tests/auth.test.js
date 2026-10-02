'use strict';

const { app, request, registerUser } = require('./helpers');

describe('auth', () => {
  test('register → 201 with token pair and user shape', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'quizkid', email: 'quizkid@example.com', password: 'Password123!' });

    expect(res.status).toBe(201);
    expect(res.body.token).toEqual(expect.any(String));
    expect(res.body.refreshToken).toEqual(expect.any(String));
    expect(res.body.user).toMatchObject({
      username: 'quizkid',
      email: 'quizkid@example.com',
      xp: 0,
      level: 1,
      coins: 0,
    });
    expect(res.body.user.id).toEqual(expect.any(String));
    expect(res.body.user.streak).toMatchObject({ count: 0 });
  });

  test('register duplicate email → 409 EMAIL_TAKEN', async () => {
    await registerUser({ username: 'alpha1', email: 'dup@example.com' });
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'alpha2', email: 'dup@example.com', password: 'Password123!' });
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('EMAIL_TAKEN');
  });

  test('register duplicate username → 409 USERNAME_TAKEN', async () => {
    await registerUser({ username: 'takenname', email: 't1@example.com' });
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'takenname', email: 't2@example.com', password: 'Password123!' });
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('USERNAME_TAKEN');
  });

  test('register weak password → 400 VALIDATION_ERROR', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ username: 'weakpw', email: 'weak@example.com', password: 'short' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('login → 200; wrong password → 401', async () => {
    await registerUser({ username: 'loginuser', email: 'login@example.com', password: 'Password123!' });

    const ok = await request(app)
      .post('/api/auth/login')
      .send({ email: 'login@example.com', password: 'Password123!' });
    expect(ok.status).toBe(200);
    expect(ok.body.token).toEqual(expect.any(String));
    expect(ok.body.user.username).toBe('loginuser');

    const bad = await request(app)
      .post('/api/auth/login')
      .send({ email: 'login@example.com', password: 'WrongPass999!' });
    expect(bad.status).toBe(401);
    expect(bad.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  test('me → 200 with token, 401 without', async () => {
    const { token } = await registerUser({ username: 'meuser', email: 'me@example.com' });

    const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.user.username).toBe('meuser');
    expect(res.body.user.email).toBe('me@example.com');
    expect(res.body.user.stats).toBeDefined();

    const anon = await request(app).get('/api/auth/me');
    expect(anon.status).toBe(401);
    expect(anon.body.error.code).toBe('UNAUTHORIZED');
  });

  test('refresh rotates tokens; old refresh token is rejected', async () => {
    const { refreshToken } = await registerUser({ username: 'refuser', email: 'ref@example.com' });

    const r1 = await request(app).post('/api/auth/refresh').send({ refreshToken });
    expect(r1.status).toBe(200);
    expect(r1.body.token).toEqual(expect.any(String));
    expect(r1.body.refreshToken).toEqual(expect.any(String));
    expect(r1.body.refreshToken).not.toBe(refreshToken);

    const replay = await request(app).post('/api/auth/refresh').send({ refreshToken });
    expect(replay.status).toBe(401);
    expect(replay.body.error.code).toBe('INVALID_TOKEN');
  });

  test('logout revokes the refresh token', async () => {
    const { token, refreshToken } = await registerUser({ username: 'logoutuser', email: 'logout@example.com' });

    const out = await request(app)
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${token}`)
      .send({ refreshToken });
    expect(out.status).toBe(200);
    expect(out.body.ok).toBe(true);

    const after = await request(app).post('/api/auth/refresh').send({ refreshToken });
    expect(after.status).toBe(401);
  });
});
