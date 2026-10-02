'use strict';

// Shared HTTP helpers: standard error envelope + async route wrapper.

function errorBody(code, message, details) {
  const body = { error: { code, message } };
  if (details !== undefined) body.error.details = details;
  return body;
}

function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = { errorBody, asyncHandler };
