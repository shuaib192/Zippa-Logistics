const axios = require('axios');
const db = require('../config/database');
const whatsappService = require('./whatsapp.service');
const { calculateFare } = require('../utils/fare_calculator');

/**
 * AI AGENT SERVICE (ai_agent.service.js)
 * The "brain" of the WhatsApp Chatbot. Powered by Groq (Llama 3).
 */

const processWhatsAppMessage = async (from, message) => {
    try {
        // 1. Get or create session
        const session = await getOrCreateSession(from);
        
        let userText = '';
        
        // 2. Handle Text or Audio
        if (message.type === 'text') {
            userText = message.text.body;
        } else if (message.type === 'audio') {
            // Audio support requires Gemini/Whisper — fallback for now
            return whatsappService.sendMessage(from, 'I currently only support text messages for booking. Voice note support is coming soon! 🎤');
        } else {
            return whatsappService.sendMessage(from, 'I\'m still learning! For now, I only understand text messages. 🚚');
        }

        // 3. Extract intent using Groq
        const intent = await extractIntent(userText, session);
        
        console.log(`User Intent for ${from}:`, intent);

        // 4. Act on intent
        await handleIntent(from, session, intent);

    } catch (err) {
        console.error('AI Agent Error:', err.message);
        await whatsappService.sendMessage(from, 'ZipBot is having a quick nap. Please try again in a moment!');
    }
};

/**
 * HELPER: Identify session
 */
const getOrCreateSession = async (phoneNumber) => {
    // Try to find existing session
    const result = await db.query(
        'SELECT * FROM whatsapp_sessions WHERE phone_number = $1',
        [phoneNumber]
    );

    if (result.rows.length > 0) {
        return result.rows[0];
    }

    // Check if user already exists in Zippa (Lookup by phone)
    let userResult;
    try {
        userResult = await db.query(
            'SELECT id FROM users WHERE phone = $1',
            [phoneNumber]
        );
    } catch (e) {
        userResult = { rows: [] };
    }
    
    const userId = userResult.rows.length > 0 ? userResult.rows[0].id : null;

    // Create new session
    const newSession = await db.query(
        'INSERT INTO whatsapp_sessions (phone_number, user_id, current_flow, flow_step) VALUES ($1, $2, $3, $4) RETURNING *',
        [phoneNumber, userId, 'idle', 'none']
    );
    return newSession.rows[0];
};

/**
 * HELPER: Extract Intent using Groq (Llama 3.3)
 */
const extractIntent = async (text, session) => {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) throw new Error('Groq API Key not found');

    const systemPrompt = `
        You are the Intent Extractor for Zippa Logistics WhatsApp AI.
        Zippa is a premium delivery service in Nigeria.
        Current context: User is in flow "${session.current_flow}" at step "${session.flow_step}".
        
        Tasks:
        1. Identify if the user wants to: 'book_ride', 'track_order', 'check_balance', 'save_landmark', or 'general_query'.
        2. Extract entities: 'pickup_location', 'dropoff_location', 'package_type'.
        
        Respond ONLY in valid JSON format:
        {
            "intent": "string",
            "entities": {
                "pickup": "string|null",
                "dropoff": "string|null",
                "package": "string|null"
            },
            "confidence": 0.0-1.0
        }
    `;

    try {
        const response = await axios.post(
            'https://api.groq.com/openai/v1/chat/completions',
            {
                model: 'llama-3.3-70b-versatile',
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: text }
                ],
                response_format: { type: 'json_object' }
            },
            {
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        return JSON.parse(response.data.choices[0].message.content);
    } catch (err) {
        console.error('Groq Intent Extraction Error:', err.message);
        // Fallback intent if AI fails
        return { intent: 'general_query', entities: {}, confidence: 0 };
    }
};

/**
 * HELPER: Handle the logic based on intent
 */
const handleIntent = async (from, session, intent) => {
    const { intent: action, entities } = intent;

    if (action === 'book_ride' || session.current_flow === 'booking') {
        return handleBookingFlow(from, session, entities);
    }

    // Default response
    await whatsappService.sendMessage(from, 'Welcome to Zippa! I can help you book a ride or track a package. What would you like to do?');
};

/**
 * BOOKING FLOW LOGIC
 */
const handleBookingFlow = async (from, session, entities) => {
    let { pickup, dropoff, package: pkgType } = entities;
    let { flow_step, flow_data } = session;

    // 1. Initial State: Start booking
    if (session.current_flow !== 'booking') {
        const initialData = { pickup, dropoff, package: pkgType };
        await updateSession(from, 'awaiting_pickup', initialData);

        if (!pickup) {
            return whatsappService.sendMessage(from, 'Sure! I can help with a booking. Where should the rider pick up the package?');
        }
    }

    // 2. State-based processing
    if (flow_step === 'awaiting_pickup') {
        const updatedData = { ...flow_data, pickup: pickup || flow_data.pickup };
        await updateSession(from, 'awaiting_dropoff', updatedData);
        return whatsappService.sendMessage(from, `Got it. Pickup is at ${updatedData.pickup}.\n\nNow, where are we delivering it to?`);
    }

    if (flow_step === 'awaiting_dropoff') {
        const updatedData = { ...flow_data, dropoff: dropoff || flow_data.dropoff };
        
        // Calculate price (Simulated distance for AI demo)
        const fareInfo = await calculateFare(5, updatedData.package || 'small'); 
        updatedData.price = fareInfo.total_fare;

        await updateSession(from, 'awaiting_confirmation', updatedData);
        
        return whatsappService.sendMessage(from, 
            'Summary of your booking:\n\n' +
            `📍 From: ${updatedData.pickup}\n` +
            `🎯 To: ${updatedData.dropoff}\n` +
            `📦 Package: ${updatedData.package || 'Standard'}\n` +
            `💰 Estimated Fare: ₦${updatedData.price.toLocaleString()}\n\n` +
            'Should I go ahead and book this for you? (Reply \'YES\' or \'CANCEL\')'
        );
    }

    if (flow_step === 'awaiting_confirmation') {
        const response = (pickup || '').toLowerCase(); // Simple extraction for now

        if (response.includes('yes') || response.includes('ok')) {
             await updateSession(from, 'idle', {}, 'none');
             return whatsappService.sendMessage(from, '✅ Order confirmed! A rider will be assigned shortly. You\'ll receive a tracking link here.');
        } else if (response.includes('cancel')) {
             await updateSession(from, 'idle', {}, 'none');
             return whatsappService.sendMessage(from, 'No problem! I\'ve cancelled the booking. Let me know if you need anything else.');
        } else {
             return whatsappService.sendMessage(from, 'I didn\'t quite catch that. Should I book it? (Reply \'YES\' or \'CANCEL\')');
        }
    }
};

/**
 * HELPER: Update session state in DB
 */
const updateSession = async (from, step, data, flow = 'booking') => {
    await db.query(
        'UPDATE whatsapp_sessions SET flow_step = $1, flow_data = $2, current_flow = $3, last_interaction = CURRENT_TIMESTAMP WHERE phone_number = $4',
        [step, JSON.stringify(data), flow, from]
    );
};

module.exports = {
    processWhatsAppMessage
};
