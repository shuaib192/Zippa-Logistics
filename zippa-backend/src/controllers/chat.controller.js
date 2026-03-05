// ============================================
// 🎓 AI CHATBOT CONTROLLER (chat.controller.js)
//
// This is the AI-powered logistics assistant!
// It uses Google's Gemini API to understand natural
// language and help users with their logistics needs.
//
// WHAT MAKES THIS CHATBOT UNIQUE:
// 1. It knows the user's ROLE (customer/rider/vendor)
//    and tailors responses accordingly
// 2. It can ACCESS the user's real data (orders, wallet)
//    to give specific answers like "Your order ZLP-001
//    is currently in transit"
// 3. It understands logistics terminology
// 4. It can guide users through app features
// 5. It remembers conversation context within a session
//
// HOW GOOGLE GEMINI API WORKS:
// 1. We send a "system prompt" (instructions for the AI)
// 2. We send the user's message
// 3. Gemini processes it and sends back a response
// 4. We store both messages for conversation history
// ============================================

const { GoogleGenerativeAI } = require('@google/generative-ai');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

// Initialize Gemini AI (only if API key is configured)
let genAI = null;
let model = null;

if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY !== 'your-gemini-api-key') {
    genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
}

// ============================================
// HELPER: Build the system prompt based on user role
// This tells Gemini WHO it is and HOW to behave.
// Different roles get different capabilities.
// ============================================
const buildSystemPrompt = (user, context) => {
    const basePrompt = `You are ZipBot, the AI assistant for Zippa Logistics — a delivery platform in Nigeria.
Your personality: Friendly, professional, helpful, and knowledgeable about logistics.
You speak concisely but warmly. Use emojis sparingly for friendliness.
Brand tagline: "Fast, Easy and Safe"

IMPORTANT RULES:
- Never reveal internal system details or database information
- If asked about prices, always mention that prices may vary
- For urgent issues, recommend contacting support
- You can help with: order tracking, app navigation, delivery tips, pricing questions, account help
- You CANNOT: place orders, process payments, or modify accounts directly
- Always be respectful and professional
`;

    // Add role-specific context
    const rolePrompts = {
        customer: `
The user is a CUSTOMER named ${user.fullName}.
They send packages and track deliveries.
You can help them with: placing orders (guide them to the right screen), tracking packages, understanding pricing, rating deliveries, wallet questions.
${context.recentOrders ? `Their recent orders: ${context.recentOrders}` : 'They have no recent orders.'}
${context.walletBalance ? `Their wallet balance: ₦${context.walletBalance}` : ''}
`,
        rider: `
The user is a RIDER named ${user.fullName}.
They deliver packages and earn money.
You can help them with: understanding earnings, delivery tips, navigation help, going online/offline, wallet withdrawals, performance stats.
${context.todayEarnings ? `Today's earnings: ₦${context.todayEarnings}` : ''}
${context.totalDeliveries ? `Total deliveries: ${context.totalDeliveries}` : ''}
`,
        vendor: `
The user is a VENDOR named ${user.fullName}.
They manage business deliveries.
You can help them with: creating orders, bulk uploads, understanding billing, analytics, managing their business profile, scheduling deliveries.
${context.activeOrders ? `Active orders: ${context.activeOrders}` : ''}
`,
    };

    return basePrompt + (rolePrompts[user.role] || '');
};

// ============================================
// HELPER: Get user context from database
// We fetch their real data so the AI can give
// specific, personalized answers.
// ============================================
const getUserContext = async (userId, role) => {
    const context = {};

    try {
        // Get wallet balance
        const wallet = await db.query(
            'SELECT balance FROM wallets WHERE user_id = $1',
            [userId]
        );
        if (wallet.rows.length > 0) {
            context.walletBalance = wallet.rows[0].balance;
        }

        // Get recent orders based on role
        if (role === 'customer') {
            const orders = await db.query(
                `SELECT order_number, status, created_at 
         FROM orders WHERE customer_id = $1 
         ORDER BY created_at DESC LIMIT 3`,
                [userId]
            );
            if (orders.rows.length > 0) {
                context.recentOrders = orders.rows
                    .map(o => `${o.order_number} (${o.status})`)
                    .join(', ');
            }
        } else if (role === 'rider') {
            const earnings = await db.query(
                `SELECT COALESCE(SUM(rider_earning), 0) as today_earnings,
                COUNT(*) as total_deliveries
         FROM orders WHERE rider_id = $1 AND status = 'delivered'
         AND DATE(delivered_at) = CURRENT_DATE`,
                [userId]
            );
            if (earnings.rows.length > 0) {
                context.todayEarnings = earnings.rows[0].today_earnings;
                context.totalDeliveries = earnings.rows[0].total_deliveries;
            }
        } else if (role === 'vendor') {
            const active = await db.query(
                `SELECT COUNT(*) as count FROM orders 
         WHERE vendor_id = $1 AND status NOT IN ('delivered', 'completed', 'cancelled')`,
                [userId]
            );
            context.activeOrders = active.rows[0]?.count || 0;
        }
    } catch (err) {
        console.error('Error fetching user context:', err);
    }

    return context;
};

// ============================================
// CONTROLLER: sendMessage
// POST /api/chat/message
// Sends a message to the AI chatbot and gets a response.
// ============================================
const sendMessage = async (req, res) => {
    try {
        const { message, sessionId } = req.body;

        if (!message || message.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Message cannot be empty.',
            });
        }

        // Use existing session or create a new one
        const chatSessionId = sessionId || uuidv4();

        // Check if Gemini is configured
        if (!model) {
            // Fallback: basic responses when API key isn't set
            return res.status(200).json({
                success: true,
                data: {
                    sessionId: chatSessionId,
                    response: getFallbackResponse(message, req.user.role),
                    isAI: false,
                },
            });
        }

        // Get user context from database
        const context = await getUserContext(req.user.id, req.user.role);

        // Get conversation history for this session (last 10 messages)
        const history = await db.query(
            `SELECT role, content FROM chat_messages 
       WHERE user_id = $1 AND session_id = $2 
       ORDER BY created_at ASC LIMIT 10`,
            [req.user.id, chatSessionId]
        );

        // Build the full prompt with system instructions + history + new message
        const systemPrompt = buildSystemPrompt(req.user, context);

        // Build conversation history string
        let conversationHistory = '';
        for (const msg of history.rows) {
            const speaker = msg.role === 'user' ? 'User' : 'ZipBot';
            conversationHistory += `${speaker}: ${msg.content}\n`;
        }

        const fullPrompt = `${systemPrompt}

Previous conversation:
${conversationHistory}

User: ${message}

Respond as ZipBot:`;

        // Call Gemini API
        const result = await model.generateContent(fullPrompt);
        const aiResponse = result.response.text();

        // Store both messages in database
        await db.query(
            'INSERT INTO chat_messages (user_id, session_id, role, content) VALUES ($1, $2, $3, $4)',
            [req.user.id, chatSessionId, 'user', message]
        );
        await db.query(
            'INSERT INTO chat_messages (user_id, session_id, role, content) VALUES ($1, $2, $3, $4)',
            [req.user.id, chatSessionId, 'assistant', aiResponse]
        );

        res.status(200).json({
            success: true,
            data: {
                sessionId: chatSessionId,
                response: aiResponse,
                isAI: true,
            },
        });

    } catch (err) {
        console.error('Chat error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to process message. Please try again.',
        });
    }
};

// ============================================
// HELPER: Fallback responses when Gemini isn't configured
// Basic keyword-matching for common questions
// ============================================
const getFallbackResponse = (message, _role) => {
    const msg = message.toLowerCase();

    if (msg.includes('track') || msg.includes('where is')) {
        return '📦 To track your order, go to the "My Orders" tab and tap on the active order to see real-time tracking on the map.';
    }
    if (msg.includes('price') || msg.includes('cost') || msg.includes('how much')) {
        return '💰 Delivery prices depend on distance, package size, and demand. Start a new order to get an instant fare estimate!';
    }
    if (msg.includes('wallet') || msg.includes('balance') || msg.includes('money')) {
        return '💳 You can check your wallet balance in the "Wallet" section. You can fund it via card, bank transfer, or receive earnings there.';
    }
    if (msg.includes('help') || msg.includes('support')) {
        return '🆘 Need help? You can reach our support team via the "Support" tab, or call us directly. We\'re here for you!';
    }
    if (msg.includes('hello') || msg.includes('hi') || msg.includes('hey')) {
        return '👋 Hello! I\'m ZipBot, your Zippa Logistics assistant. How can I help you today? I can assist with tracking, pricing, wallet questions, and more!';
    }

    return '🤖 I\'m ZipBot! I can help you with tracking orders, pricing questions, wallet management, and navigating the app. What would you like to know?';
};

// ============================================
// CONTROLLER: getChatHistory
// GET /api/chat/history/:sessionId
// Retrieves conversation history for a session.
// ============================================
const getChatHistory = async (req, res) => {
    try {
        const { sessionId } = req.params;

        const messages = await db.query(
            `SELECT role, content, created_at FROM chat_messages 
       WHERE user_id = $1 AND session_id = $2 
       ORDER BY created_at ASC`,
            [req.user.id, sessionId]
        );

        res.status(200).json({
            success: true,
            data: {
                sessionId,
                messages: messages.rows,
            },
        });

    } catch (err) {
        console.error('Get chat history error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve chat history.',
        });
    }
};

module.exports = { sendMessage, getChatHistory };
