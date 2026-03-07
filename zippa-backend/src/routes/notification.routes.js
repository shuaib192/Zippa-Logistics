const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { getNotifications, markAsRead } = require('../controllers/notification.controller');

router.use(authenticate);

router.get('/', getNotifications);
router.put('/:id/read', markAsRead);

module.exports = router;
