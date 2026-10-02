'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const env = require('../config/env');

function signAccessToken(userId) {
  return jwt.sign({ sub: String(userId), type: 'access' }, env.jwtSecret, {
    expiresIn: env.jwtAccessExpiresIn,
  });
}

function newJti() {
  return crypto.randomBytes(16).toString('hex');
}

function signRefreshToken(userId, jti) {
  return jwt.sign({ sub: String(userId), type: 'refresh', jti }, env.jwtSecret, {
    expiresIn: env.jwtRefreshExpiresIn,
  });
}

// Store only the hash of the refresh-token jti, never the token itself.
function hashToken(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function verifyToken(token) {
  return jwt.verify(token, env.jwtSecret);
}

module.exports = { signAccessToken, signRefreshToken, newJti, hashToken, verifyToken };
