'use strict';

const request = require('supertest');
const createApp = require('../src/app');

const app = createApp();

let counter = 0;
function unique(suffix) {
  counter += 1;
  return `${suffix}_${Date.now()}_${counter}`;
}

async function registerUser({ username, email, password = 'Password123!' } = {}) {
  const res = await request(app)
    .post('/api/auth/register')
    .send({ username: username || unique('user'), email: email || `${unique('u')}@example.com`, password });
  if (res.status !== 201) throw new Error(`register failed: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body; // { token, refreshToken, user }
}

module.exports = { app, request, registerUser, unique };
