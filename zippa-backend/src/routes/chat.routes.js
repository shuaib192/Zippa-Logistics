// ============================================
// 🎓 CHAT ROUTES (chat.routes.js)
//
// All chat routes require authentication because
// the AI needs to know WHO is chatting to give
// personalized, role-specific responses.
// ============================================

const express = require('express');
const router = express.Router();

const { authenticate } = require('../middleware/auth.middleware');
const { sendMessage, getChatHistory } = require('../controllers/chat.controller');

// POST /api/chat/message — Send a message to ZipBot
router.post('/message', authenticate, sendMessage);

// GET /api/chat/history/:sessionId — Get chat history
router.get('/history/:sessionId', authenticate, getChatHistory);

module.exports = router;
