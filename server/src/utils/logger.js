'use strict';

// Tiny structured logger. This is the ONLY place in src/ allowed to touch the
// console — everything else must go through this module.

const LEVELS = { debug: 0, info: 1, warn: 2, error: 3 };
const configured = (process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug')).toLowerCase();
const threshold = LEVELS[configured] ?? LEVELS.debug;

function emit(level, args) {
  if ((LEVELS[level] ?? 99) < threshold) return;
  const ts = new Date().toISOString();
  const method = level === 'debug' ? 'log' : level;
  // eslint-disable-next-line no-console
  console[method](`[${ts}] [${level.toUpperCase()}]`, ...args);
}

module.exports = {
  debug: (...args) => emit('debug', args),
  info: (...args) => emit('info', args),
  warn: (...args) => emit('warn', args),
  error: (...args) => emit('error', args),
};
