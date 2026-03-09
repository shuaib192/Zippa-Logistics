const express = require('express');
const router = express.Router();
const webhookController = require('../controllers/paystack_webhook.controller');

// Paystack Webhook
// This should be mapped to: POST /api/webhooks/paystack
router.post('/paystack', webhookController.handleWebhook);

module.exports = router;
