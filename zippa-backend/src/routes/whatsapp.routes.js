const express = require('express');
const router = express.Router();
const whatsappController = require('../controllers/whatsapp.controller');

/**
 * WHATSAPP WEBHOOK ROUTES
 * These endpoints are called by Meta (WhatsApp) servers
 */

// 1. Webhook Verification (GET)
// Meta calls this when you first set up the webhook to verify ownership
router.get('/webhook', whatsappController.verifyWebhook);

// 2. Incoming Messages (POST)
// Meta calls this every time a user sends a message, a status updates, etc.
router.post('/webhook', whatsappController.handleIncoming);

module.exports = router;
