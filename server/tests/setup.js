'use strict';

// Global jest setup: in-memory MongoDB for every test file.
// NOTE: this file must not use the src logger (it runs before env is loaded).

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-for-jest-only';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';

const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

let mongo;

beforeAll(async () => {
  mongo = await MongoMemoryServer.create();
  await mongoose.connect(mongo.getUri());
});

afterAll(async () => {
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
});

afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const coll of Object.values(collections)) {
    await coll.deleteMany({});
  }
});
