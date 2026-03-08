const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
const db = require('../config/database');
const whatsappService = require('./whatsapp.service');
const landmarkService = require('./landmark.service');
const { calculateFare } = require('../utils/fare_calculator');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

/**
 * AI AGENT SERVICE (ai_agent.service.js)
 * The "brain" of the WhatsApp Chatbot.
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
            console.log(`Analyzing voice note from ${from}...`);
            userText = await transcribeAudio(message.audio.id);
        } else {
            return whatsappService.sendMessage(from, "I'm still learning! For now, I only understand text and voice notes. 🎤");
        }

        // 3. Extract intent using Gemini
        const intent = await extractIntent(userText, session);
        
        console.log(`User Intent for ${from}:`, intent);

        // 3. Act on intent
        await handleIntent(from, session, intent);

    } catch (err) {
        console.error('AI Agent Error:', err);
        await whatsappService.sendMessage(from, "ZipBot is having a quick nap. Please try again in a moment!");
    }
};

/**
 * HELPER: Identify session
 */
const getOrCreateSession = async (phoneNumber) => {
    const result = await db.query(
        'SELECT * FROM whatsapp_sessions WHERE phone_number = $1',
        [phoneNumber]
    );

    if (result.rows.length > 0) {
        return result.rows[0];
    }

    // Check if user already exists in Zippa (Lookup by phone)
    const userResult = await db.query(
        'SELECT id FROM users WHERE phone = $1',
        [phoneNumber]
    );
    const userId = userResult.rows.length > 0 ? userResult.rows[0].id : null;

    // Create new session
    const newSession = await db.query(
        'INSERT INTO whatsapp_sessions (phone_number, user_id, current_flow, flow_step) VALUES ($1, $2, $3, $4) RETURNING *',
        [phoneNumber, userId, 'idle', 'none']
    );
    return newSession.rows[0];
};

/**
 * HELPER: Extract Intent using Gemini
 */
const extractIntent = async (text, session) => {
    const systemPrompt = `
        You are the Intent Extractor for Zippa Logistics WhatsApp AI.
        Current context: User is in flow "${session.current_flow}" at step "${session.flow_step}".
        
        Tasks:
        1. Identify if the user wants to: 'book_ride', 'track_order', 'check_balance', 'save_landmark', or 'general_query'.
        2. Extract entities: 'pickup_location', 'dropoff_location', 'package_type'.
        
        Respond ONLY in JSON format:
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

    const result = await model.generateContent([systemPrompt, text]);
    const response = await result.response;
    const jsonStr = response.text().replace(/```json/g, '').replace(/```/g, '').trim();
    return JSON.parse(jsonStr);
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
    await whatsappService.sendMessage(from, "Welcome to Zippa! I can help you book a ride or track a package. What would you like to do? (You can even send a voice note!)");
};

/**
 * BOOKING FLOW LOGIC (The multi-step conversation)
 */
const handleBookingFlow = async (from, session, entities) => {
    let { pickup, dropoff, package: pkgType } = entities;
    let { flow_step, flow_data, user_id } = session;

    // 1. Initial State: Start booking
    if (session.current_flow !== 'booking') {
        const initialData = { pickup, dropoff, package: pkgType };
        await updateSession(from, 'awaiting_pickup', initialData);

        if (!pickup) {
            // Suggest previous landmarks if available
            const landmarkMsg = user_id ? " (I can also see your saved landmarks!)" : "";
            return whatsappService.sendMessage(from, `Sure! Where should the rider pick up the package?${landmarkMsg}`);
        }
    }

    // 2. State-based processing
    if (flow_step === 'awaiting_pickup') {
        // Check if user mentioned a landmark
        const landmark = await landmarkService.findLandmark(user_id, pickup || "");
        if (landmark) {
            pickup = `${landmark.name} (${landmark.description})`;
            console.log(`Matched landmark: ${landmark.name}`);
        }

        const updatedData = { ...flow_data, pickup: pickup || flow_data.pickup };
        await updateSession(from, 'awaiting_dropoff', updatedData);
        return whatsappService.sendMessage(from, `Got it. Pickup is at ${updatedData.pickup}.\n\nNow, where are we delivering it to?`);
    }

    if (flow_step === 'awaiting_dropoff') {
        const landmark = await landmarkService.findLandmark(user_id, dropoff || "");
        if (landmark) {
            dropoff = `${landmark.name} (${landmark.description})`;
        }

        const updatedData = { ...flow_data, dropoff: dropoff || flow_data.dropoff };
        
        // Calculate price (using a default 5km for the AI until we add full Geocoding)
        const fareInfo = calculateFare(5, updatedData.package || 'small'); 
        updatedData.price = fareInfo.total_fare;

        await updateSession(from, 'awaiting_confirmation', updatedData);
        
        return whatsappService.sendMessage(from, 
            `Summary of your booking:\n\n` +
            `📍 From: ${updatedData.pickup}\n` +
            `🎯 To: ${updatedData.dropoff}\n` +
            `📦 Package: ${updatedData.package || 'Standard'}\n` +
            `💰 Estimated Fare: ₦${updatedData.price.toLocaleString()}\n\n` +
            `Should I go ahead and book this for you? (Reply 'YES', 'OK', or 'CANCEL')`
        );
    }

    if (flow_step === 'awaiting_confirmation') {
        const response = (pickup || "").toLowerCase(); // entities.pickup often contains the full text in this simple extractor

        if (response.includes('yes') || response.includes('ok')) {
             await updateSession(from, 'idle', {}, 'none');
             return whatsappService.sendMessage(from, "✅ Order confirmed! A rider will be assigned shortly. You'll receive a tracking link here.");
        } else if (response.includes('cancel')) {
             await updateSession(from, 'idle', {}, 'none');
             return whatsappService.sendMessage(from, "No problem! I've cancelled the booking. Let me know if you need anything else.");
        } else {
             return whatsappService.sendMessage(from, "I didn't quite catch that. Should I book it? (Reply 'YES' or 'CANCEL')");
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

/**
 * HELPER: Transcribe Audio using Gemini Multimodal
 */
const transcribeAudio = async (mediaId) => {
    try {
        const token = process.env.WHATSAPP_ACCESS_TOKEN;
        
        // 1. Get media URL from Meta
        const mediaRes = await axios.get(`https://graph.facebook.com/v19.0/${mediaId}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const mediaUrl = mediaRes.data.url;

        // 2. Download audio bytes
        const audioRes = await axios.get(mediaUrl, {
            headers: { 'Authorization': `Bearer ${token}` },
            responseType: 'arraybuffer'
        });
        const audioData = Buffer.from(audioRes.data).toString('base64');

        // 3. Send to Gemini for transcription
        const result = await model.generateContent([
            "Transcribe this Nigerian voice note exactly. It might be in English, Pidgin, or a local language. If it's a booking request, capture the locations.",
            {
                inlineData: {
                    data: audioData,
                    mimeType: 'audio/mp3' // Meta usually sends .ogg/mp4 but Gemini expects mime
                }
            }
        ]);
        
        return result.response.text();
    } catch (err) {
        console.error('Transcription Error:', err);
        return "";
    }
};

module.exports = {
    processWhatsAppMessage
};
