'use strict';

const { Router } = require('express');
const { query } = require('express-validator');
const validate = require('../middleware/validate');
const ctrl = require('../controllers/questionController');

const router = Router();

router.get(
  '/',
  [
    query('category').optional().isString().withMessage('category must be a string').notEmpty().withMessage('category must not be empty'),
    query('difficulty').optional().isIn(['easy', 'medium', 'hard']).withMessage('difficulty must be easy, medium or hard'),
    query('count').optional().isInt({ min: 1, max: 50 }).withMessage('count must be 1–50').toInt(),
  ],
  validate,
  ctrl.list
);

module.exports = router;
