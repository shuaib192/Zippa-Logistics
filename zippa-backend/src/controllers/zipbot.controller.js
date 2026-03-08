const axios = require('axios');

/**
 * Handle ZipBot chat requests using Groq AI
 * POST /api/chat/zipbot
 */
const chatWithZipBot = async (req, res) => {
    const { message, history } = req.body;

    if (!message) {
        return res.status(400).json({ success: false, message: 'Message is required.' });
    }

    try {
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) {
            return res.status(500).json({ success: false, message: 'Groq API key not configured.' });
        }

        // Prepare context (Quick summary of Zippa for the AI)
        const systemPrompt = `
            You are ZipBot, the official AI assistant for Zippa Logistics. 
            Zippa is a premium logistics platform in Nigeria providing fast and safe delivery services.
            Your tone is professional, helpful, and friendly.
            
            Key Information:
            - Services: Same-day delivery, scheduled delivery, interstate logistics (coming soon).
            - Pricing: Based on distance and package size.
            - Support: support@zippalogistics.com
            
            Keep responses concise and helpful. 
            Address the user by their name if available: ${req.user.full_name}.
        `;

        // Prepare messages for Groq API
        const messages = [
            { role: 'system', content: systemPrompt }
        ];

        // Add history if available
        if (history && Array.isArray(history)) {
            history.forEach(msg => {
                messages.push({ role: msg.role === 'user' ? 'user' : 'assistant', content: msg.content });
            });
        }

        messages.push({ role: 'user', content: message });

        // Call Groq API (OpenAI compatible)
        const response = await axios.post(
            'https://api.groq.com/openai/v1/chat/completions',
            {
                model: 'llama-3.3-70b-versatile',
                messages: messages,
                temperature: 0.7,
                max_tokens: 1024
            },
            {
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        const reply = response.data.choices[0].message.content;

        res.status(200).json({
            success: true,
            reply: reply
        });

    } catch (err) {
        console.error('ZipBot error:', err.response?.data || err.message);
        res.status(500).json({
            success: false,
            message: 'ZipBot is currently sleeping. Please try again later.'
        });
    }
};

module.exports = { chatWithZipBot };
