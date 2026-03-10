const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { chatWithZipBot } = require('../controllers/zipbot.controller');
const ChatController = require('../controllers/chat.controller');

router.use(authenticate);

// AI Chatbot
router.post('/zipbot', chatWithZipBot);

// Order Messaging
router.post('/order/send', ChatController.sendMessage);
router.get('/order/:orderId', ChatController.getMessages);

module.exports = router;
