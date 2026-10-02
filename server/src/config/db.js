'use strict';

const mongoose = require('mongoose');
const env = require('./env');
const logger = require('../utils/logger');

async function connectDb(uri) {
  const target = uri || env.mongoUri;
  mongoose.set('strictQuery', true);
  await mongoose.connect(target);
  logger.info(`MongoDB connected: ${mongoose.connection.host}/${mongoose.connection.name}`);
  return mongoose.connection;
}

module.exports = { connectDb };
