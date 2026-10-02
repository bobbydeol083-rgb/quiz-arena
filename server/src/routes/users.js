'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/userController');

const router = Router();

router.get('/:id', ctrl.getById);

module.exports = router;
