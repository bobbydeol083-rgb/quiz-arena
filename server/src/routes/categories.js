'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/categoryController');

const router = Router();

router.get('/', ctrl.list);

module.exports = router;
