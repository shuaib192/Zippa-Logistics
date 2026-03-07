const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { submitRating } = require('../controllers/rating.controller');

router.use(authenticate);

router.post('/', submitRating);

module.exports = router;
