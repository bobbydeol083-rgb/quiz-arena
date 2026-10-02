'use strict';

const { app, request, registerUser } = require('./helpers');
const User = require('../src/models/User');

describe('nearby players', () => {
  test('$near query returns close players, excludes self and far players', async () => {
    await User.syncIndexes();

    const u1 = await registerUser({ username: 'delhi1', email: 'delhi1@example.com' });
    const u2 = await registerUser({ username: 'delhi2', email: 'delhi2@example.com' });
    const u3 = await registerUser({ username: 'mumbai1', email: 'mumbai1@example.com' });

    // Delhi ~ Connaught Place; u2 ~70m away; u3 in Mumbai (~1150km away).
    await User.findByIdAndUpdate(u1.user.id, { location: { type: 'Point', coordinates: [77.2090, 28.6139] } });
    await User.findByIdAndUpdate(u2.user.id, { location: { type: 'Point', coordinates: [77.2096, 28.6143] } });
    await User.findByIdAndUpdate(u3.user.id, { location: { type: 'Point', coordinates: [72.8777, 19.0760] } });

    const res = await request(app)
      .get('/api/players/nearby?maxDistance=5000&limit=20')
      .set('Authorization', `Bearer ${u1.token}`);

    expect(res.status).toBe(200);
    const ids = res.body.map((p) => p.id);
    expect(ids).toContain(u2.user.id);
    expect(ids).not.toContain(u1.user.id); // self excluded
    expect(ids).not.toContain(u3.user.id); // too far

    const near = res.body.find((p) => p.id === u2.user.id);
    expect(near.distanceM).toBeLessThan(500);
    expect(near).toMatchObject({ username: 'delhi2' });
    expect(near).toHaveProperty('online');
    expect(near).not.toHaveProperty('email');
  });

  test('tight maxDistance excludes everyone', async () => {
    await User.syncIndexes();
    const u1 = await registerUser({ username: 'close1', email: 'close1@example.com' });
    const u2 = await registerUser({ username: 'close2', email: 'close2@example.com' });
    await User.findByIdAndUpdate(u1.user.id, { location: { type: 'Point', coordinates: [77.2090, 28.6139] } });
    await User.findByIdAndUpdate(u2.user.id, { location: { type: 'Point', coordinates: [77.2096, 28.6143] } });

    const res = await request(app)
      .get('/api/players/nearby?maxDistance=10')
      .set('Authorization', `Bearer ${u1.token}`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(0);
  });

  test('POST /api/players/location updates coordinates', async () => {
    const u = await registerUser({ username: 'locuser', email: 'locuser@example.com' });
    const res = await request(app)
      .post('/api/players/location')
      .set('Authorization', `Bearer ${u.token}`)
      .send({ lng: 77.2, lat: 28.6 });
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);

    const db = await User.findById(u.user.id);
    expect(db.location.coordinates).toEqual([77.2, 28.6]);
  });

  test('invalid coordinates → 400; unauthenticated → 401', async () => {
    const u = await registerUser({ username: 'locuser2', email: 'locuser2@example.com' });
    const bad = await request(app)
      .post('/api/players/location')
      .set('Authorization', `Bearer ${u.token}`)
      .send({ lng: 999, lat: 28.6 });
    expect(bad.status).toBe(400);

    const anon = await request(app).get('/api/players/nearby');
    expect(anon.status).toBe(401);
  });
});
