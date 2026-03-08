const db = require('../config/database');
const aiAgentService = require('../services/ai_agent.service');

/**
 * WHATSAPP CONTROLLER (whatsapp.controller.js)
 * Handles all logic for the WhatsApp AI Agent.
 */

// 1. VERIFY WEBHOOK (GET)
// Required by Meta to confirm this server is yours.
const verifyWebhook = (req, res) => {
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    // Check if mode and token are present
    if (mode && token) {
        // Check the mode and token sent is correct
        if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
            // Respond with the challenge token from the request
            console.log('WEBHOOK_VERIFIED');
            return res.status(200).send(challenge);
        } else {
            // Responds with '403 Forbidden' if verify tokens do not match
            return res.sendStatus(403);
        }
    }
};

// 2. HANDLE INCOMING (POST)
// This is the "brain" that receives messages and decides what to do.
const handleIncoming = async (req, res) => {
    try {
        const { body } = req;

        // Check if this is a WhatsApp message payload
        if (body.object === 'whatsapp_business_account') {
            if (
                body.entry &&
                body.entry[0].changes &&
                body.entry[0].changes[0].value.messages &&
                body.entry[0].changes[0].value.messages[0]
            ) {
                const message = body.entry[0].changes[0].value.messages[0];
                const from = message.from; // User's phone number
                const msgType = message.type; // text, audio, image, etc.

                console.log(`Incoming ${msgType} message from ${from}`);

                // Send 200 OK immediately so Meta doesn't retry
                res.sendStatus(200);

                // PROCESS MESSAGE ASYNCHRONOUSLY
                // (We don't want Meta to wait for our AI to think)
                processBackground(from, message);
                return;
            }
            return res.sendStatus(200);
        } else {
            // Not a WhatsApp event
            return res.sendStatus(404);
        }
    } catch (err) {
        console.error('WhatsApp Webhook Error:', err);
        res.sendStatus(500);
    }
};

/**
 * INTERNAL PROCESSOR
 * This runs in the background to handle the AI logic.
 */
const processBackground = async (from, message) => {
    try {
        console.log(`Processing ${message.type} in background...`);
        await aiAgentService.processWhatsAppMessage(from, message);
    } catch (err) {
        console.error('Background Processing Error:', err);
    }
};

module.exports = {
    verifyWebhook,
    handleIncoming
};
