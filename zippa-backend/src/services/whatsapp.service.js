const axios = require('axios');

/**
 * WHATSAPP SERVICE (whatsapp.service.js)
 * Handles sending messages to the WhatsApp Cloud API.
 */

const sendMessage = async (to, text) => {
    try {
        const token = process.env.WHATSAPP_ACCESS_TOKEN;
        const phoneId = process.env.WHATSAPP_PHONE_NUMBER_ID;

        if (!token || !phoneId) {
            console.warn('WhatsApp API not configured in .env. Skipping send.');
            return;
        }

        const url = `https://graph.facebook.com/v19.0/${phoneId}/messages`;

        const response = await axios.post(
            url,
            {
                messaging_product: 'whatsapp',
                to: to,
                type: 'text',
                text: { body: text }
            },
            {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        console.log(`Message sent to ${to}: ${response.data.messages[0].id}`);
        return response.data;
    } catch (err) {
        console.error('Send Message Error:', err.response?.data || err.message);
    }
};

module.exports = {
    sendMessage
};
