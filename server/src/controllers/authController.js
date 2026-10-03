'use strict';

const bcrypt = require('bcryptjs');
const User = require('../models/User');
const env = require('../config/env');
const { signAccessToken, signRefreshToken, newJti, hashToken, verifyToken } = require('../utils/tokens');
const { publicUser } = require('../utils/serialize');
const { errorBody, asyncHandler } = require('../utils/http');
const { applyCoins } = require('../utils/coins');

async function issueTokenPair(user) {
  const jti = newJti();
  const token = signAccessToken(user._id);
  const refreshToken = signRefreshToken(user._id, jti);
  user.refreshTokens.push(hashToken(jti));
  if (user.refreshTokens.length > 10) user.refreshTokens = user.refreshTokens.slice(-10);
  await user.save();
  return { token, refreshToken };
}

function authPayload(user, token, refreshToken) {
  return { token, refreshToken, user: publicUser(user, { includeEmail: true, includeStats: true }) };
}

/// 6-char unambiguous referral code (no 0/O/1/I).
function makeReferralCode() {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

async function uniqueReferralCode() {
  for (let i = 0; i < 10; i++) {
    const code = makeReferralCode();
    if (!(await User.exists({ referralCode: code }))) return code;
  }
  // Astronomically unlikely; fall back to a timestamp-suffixed code.
  return `QA${Date.now().toString(36).toUpperCase().slice(-4)}`;
}

const REFERRER_REWARD = 100;
const REFEREE_REWARD = 50;

const register = asyncHandler(async (req, res) => {
  const { username, email, password, referralCode } = req.body;
  const normalizedEmail = String(email).toLowerCase();

  if (await User.findOne({ email: normalizedEmail })) {
    return res.status(409).json(errorBody('EMAIL_TAKEN', 'Email is already registered'));
  }
  if (await User.findOne({ username })) {
    return res.status(409).json(errorBody('USERNAME_TAKEN', 'Username is already taken'));
  }

  const passwordHash = await bcrypt.hash(password, env.bcryptRounds);
  const user = await User.create({
    username,
    email: normalizedEmail,
    passwordHash,
    referralCode: await uniqueReferralCode(),
  });

  // Refer & earn: credit both sides when a valid code was supplied.
  if (referralCode) {
    const referrer = await User.findOne({
      referralCode: String(referralCode).trim().toUpperCase(),
    });
    if (referrer && String(referrer._id) !== String(user._id)) {
      await applyCoins(referrer, REFERRER_REWARD, `Referral: ${user.username} joined`, 'referral', user._id);
      referrer.referralCount += 1;
      await referrer.save();
      await applyCoins(user, REFEREE_REWARD, 'Referral signup bonus', 'referral', referrer._id);
      user.referredBy = referrer._id;
      await user.save();
    }
  }

  const { token, refreshToken } = await issueTokenPair(user);
  res.status(201).json(authPayload(user, token, refreshToken));
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email: String(email).toLowerCase() }).select('+passwordHash +refreshTokens');
  const ok = user && (await bcrypt.compare(password, user.passwordHash));
  if (!ok) {
    return res.status(401).json(errorBody('INVALID_CREDENTIALS', 'Invalid email or password'));
  }
  const { token, refreshToken } = await issueTokenPair(user);
  res.json(authPayload(user, token, refreshToken));
});

const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  let decoded;
  try {
    decoded = verifyToken(refreshToken);
  } catch (e) {
    return res.status(401).json(errorBody('INVALID_TOKEN', e.name === 'TokenExpiredError' ? 'Refresh token expired' : 'Invalid refresh token'));
  }
  if (decoded.type !== 'refresh' || !decoded.jti) {
    return res.status(401).json(errorBody('INVALID_TOKEN', 'Invalid refresh token'));
  }

  const user = await User.findById(decoded.sub).select('+refreshTokens');
  const hashed = hashToken(decoded.jti);
  if (!user || !user.refreshTokens.includes(hashed)) {
    return res.status(401).json(errorBody('INVALID_TOKEN', 'Refresh token revoked or unknown'));
  }

  // Rotate: drop the used jti, issue a fresh pair.
  user.refreshTokens = user.refreshTokens.filter((h) => h !== hashed);
  const pair = await issueTokenPair(user);
  res.json(pair);
});

const logout = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body || {};
  const user = await User.findById(req.userId).select('+refreshTokens');
  if (user) {
    if (refreshToken) {
      try {
        const decoded = verifyToken(refreshToken);
        if (decoded.type === 'refresh' && decoded.jti) {
          const hashed = hashToken(decoded.jti);
          user.refreshTokens = user.refreshTokens.filter((h) => h !== hashed);
        }
      } catch {
        // Invalid token in body: fall through and clear all sessions below.
        user.refreshTokens = [];
      }
    } else {
      user.refreshTokens = [];
    }
    await user.save();
  }
  res.json({ ok: true });
});

const me = asyncHandler(async (req, res) => {
  res.json({ user: publicUser(req.user, { includeEmail: true, includeStats: true }) });
});

module.exports = { register, login, refresh, logout, me };
