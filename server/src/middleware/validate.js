'use strict';

const { validationResult } = require('express-validator');
const { errorBody } = require('../utils/http');

// Final step in every validation chain: 400 { error: { code, message, details } }.
function validate(req, res, next) {
  const result = validationResult(req);
  if (!result.isEmpty()) {
    const details = result.array().map((e) => ({ field: e.path || e.param, message: e.msg }));
    return res.status(400).json(errorBody('VALIDATION_ERROR', 'Invalid request data', details));
  }
  next();
}

module.exports = validate;
