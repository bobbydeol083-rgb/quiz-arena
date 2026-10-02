'use strict';

const http = require('http');
const { Server } = require('socket.io');
const env = require('./config/env');
const logger = require('./utils/logger');
const { connectDb } = require('./config/db');
const createApp = require('./app');
const initSocket = require('./socket');

async function main() {
  await connectDb();

  const app = createApp();
  const server = http.createServer(app);
  const io = new Server(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] }, // open for dev; lock down via CLIENT_URL in prod
    pingTimeout: 30000,
  });
  initSocket(io);
  app.set('io', io);

  server.listen(env.port, () => {
    logger.info(`QuizArena server listening on :${env.port} (${env.nodeEnv})`);
  });

  const shutdown = (signal) => {
    logger.info(`Received ${signal}, shutting down…`);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 10000).unref();
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  logger.error('Fatal startup error', err);
  process.exit(1);
});
