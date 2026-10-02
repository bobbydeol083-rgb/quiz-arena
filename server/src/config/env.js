'use strict';

require('dotenv').config();

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '5000', 10),
  mongoUri: process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/quizarena',
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-me',
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  clientUrl: process.env.CLIENT_URL || '*',
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '10', 10),
  isTest: (process.env.NODE_ENV || 'test') === 'test',
  isProd: (process.env.NODE_ENV || '') === 'production',
};

if (env.isProd && (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'dev-secret-change-me')) {
  throw new Error('JWT_SECRET must be set in production');
}

module.exports = env;
