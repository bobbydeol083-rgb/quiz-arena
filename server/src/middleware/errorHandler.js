'use strict';

const logger = require('../utils/logger');
const { errorBody, asyncHandler } = require('../utils/http');

function notFound(req, res) {
  res.status(404).json(errorBody('NOT_FOUND', `Route ${req.method} ${req.originalUrl} not found`));
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  // Mongoose document validation
  if (err.name === 'ValidationError') {
    const details = Object.values(err.errors || {}).map((e) => ({ field: e.path, message: e.message }));
    return res.status(400).json(errorBody('VALIDATION_ERROR', 'Invalid data', details));
  }
  // Duplicate key (unique indexes)
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || 'field';
    return res.status(409).json(errorBody('DUPLICATE', `${field} is already taken`));
  }
  // Bad ObjectId
  if (err.name === 'CastError') {
    return res.status(400).json(errorBody('INVALID_ID', `Invalid id: ${err.value}`));
  }

  const status = Number.isInteger(err.status) ? err.status : 500;
  const code = err.code || 'INTERNAL_ERROR';
  if (status >= 500) logger.error(`${req.method} ${req.originalUrl}`, err);
  const message = status >= 500 && process.env.NODE_ENV === 'production'
    ? 'Something went wrong'
    : err.message || 'Something went wrong';
  res.status(status).json(errorBody(code, message));
}

module.exports = { notFound, errorHandler, asyncHandler };
