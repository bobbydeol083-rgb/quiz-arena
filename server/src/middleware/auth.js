'use strict';

const User = require('../models/User');
const { verifyToken } = require('../utils/tokens');
const { errorBody, asyncHandler } = require('../utils/http');

function unauthorized(message = 'Authentication required') {
  const err = new Error(message);
  err.status = 401;
  err.code = 'UNAUTHORIZED';
  return err;
}

// Requires `Authorization: Bearer <accessToken>`.
// Attaches req.userId and req.user (passwordHash/refreshTokens excluded).
const requireAuth = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) throw unauthorized('Missing or malformed Authorization header');

  let decoded;
  try {
    decoded = verifyToken(token);
  } catch (e) {
    throw unauthorized(e.name === 'TokenExpiredError' ? 'Access token expired' : 'Invalid access token');
  }
  if (decoded.type !== 'access') throw unauthorized('Invalid access token');

  const user = await User.findById(decoded.sub);
  if (!user) throw unauthorized('User no longer exists');

  req.userId = String(user._id);
  req.user = user;
  next();
});

module.exports = { requireAuth, errorBody };
