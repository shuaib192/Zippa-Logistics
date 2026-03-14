// ============================================
// 🎓 MAIN APPLICATION FILE (app.js)
//
// This is the ENTRY POINT of our backend server.
// When you run "npm run dev", THIS file runs first.
//
// WHAT DOES EXPRESS DO?
// Express is a web framework for Node.js. It helps you:
// 1. Listen for HTTP requests (GET, POST, PUT, DELETE)
// 2. Route requests to the right handler
// 3. Send responses back to the client (mobile app)
//
// MIDDLEWARE EXPLAINED:
// Middleware are functions that run BEFORE your route handlers.
// Think of them as security checkpoints at an airport:
// Check 1 (CORS): "Are you allowed to talk to this server?"
// Check 2 (Helmet): "Let me add security headers"
// Check 3 (JSON parser): "Let me read your data"
// Check 4 (Auth): "Are you logged in?"
// Then finally: Your actual route handler runs
// ============================================

// Load environment variables FIRST (before anything else)
require('dotenv').config();

// Import required packages
const express = require('express');     // Web framework
const cors = require('cors');           // Cross-Origin Resource Sharing
const helmet = require('helmet');       // Security headers
const morgan = require('morgan');       // Request logging
const rateLimit = require('express-rate-limit'); // Rate limiting

// Import our route files (we'll create these next)
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const notificationRoutes = require('./routes/notification.routes');
const ratingRoutes = require('./routes/rating.routes');
const chatRoutes = require('./routes/chat.routes');
const orderRoutes = require('./routes/order.routes');
const walletRoutes = require('./routes/wallet.routes');
const whatsappRoutes = require('./routes/whatsapp.routes');
const vendorRoutes = require('./routes/vendor.routes');
const productRoutes = require('./routes/product.routes');
const webhookRoutes = require('./routes/webhook.routes');
const adminRoutes = require('./routes/admin.routes');
const path = require('path');

// Create the Express application
const app = express();

// ============================================
// MIDDLEWARE SETUP
// ============================================

// 1. CORS — Cross-Origin Resource Sharing
// This allows our Flutter app to communicate with this server.
// Without CORS, browsers/apps block requests to different domains.
app.use(cors({
    origin: '*', // In production, restrict this to your app's domain
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));

// 2. Helmet — Security Headers
// Adds headers like X-Content-Type-Options, X-Frame-Options, etc.
// These protect against common web attacks.
app.use(helmet());

// 3. JSON Body Parser
// Allows the server to read JSON data sent in request bodies.
// e.g., when the app sends { "email": "user@example.com" }
app.use(express.json({ limit: '10mb' }));
// limit: '10mb' allows larger payloads (needed for image uploads)

// 4. URL-encoded parser (for form submissions)
app.use(express.urlencoded({ extended: true }));

// 5. Morgan — Request Logger
// Logs every incoming request to the console.
// 'dev' format shows: GET /api/users 200 3ms
// This is super helpful for debugging!
if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
}

// 6. Rate Limiting — Prevents API Abuse
// Limits each IP address to 100 requests per 15 minutes.
// This stops hackers from flooding your server.
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes (in milliseconds)
    max: 1000,                 // Max 1000 requests per window (relaxed for dev)
    message: {
        success: false,
        message: 'Too many requests. Please try again in 15 minutes.',
    },
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', limiter); // Apply to all API routes

// ============================================
// ROUTES
// ============================================

// Health check endpoint — used by CI/CD and monitoring
// If this returns 200, the server is alive and well.
app.get('/api/health', (_req, res) => {
    res.status(200).json({
        success: true,
        message: 'Zippa Logistics API is running',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
    });
});

// Public push endpoint for PHP admin panel (MUST be before authenticated admin routes)
const NotificationService = require('./services/notification.service');
app.post('/api/push/broadcast', (req, res) => {
    const { title, body, target } = req.body;
    
    if (!title || !body) {
        return res.status(400).json({ success: false, message: 'title and body required' });
    }
    
    console.log(`🔔 PHP Admin push to ${target}: ${title}`);
    
    if (target === 'all') {
        NotificationService.sendToTopic('customers', { title, body, data: { type: 'broadcast' } });
        NotificationService.sendToTopic('riders', { title, body, data: { type: 'broadcast' } });
        NotificationService.sendToTopic('vendors', { title, body, data: { type: 'broadcast' } });
    } else if (['customer', 'rider', 'vendor'].includes(target)) {
        const topicName = target + 's';
        NotificationService.sendToTopic(topicName, { title, body, data: { type: 'broadcast' } });
    }
    
    res.status(200).json({ success: true, message: 'Push sent' });
});

// Mount route modules
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/whatsapp', whatsappRoutes);
app.use('/api/vendors', vendorRoutes);
app.use('/api/products', productRoutes);
app.use('/api/webhooks', webhookRoutes);
app.use('/api/admin', adminRoutes);

// 7. Static file serving for Uploads (KYC, Avatars, etc.)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Static file serving for Admin Dashboard
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));
// Support for SPA routing - fallback to index.html for any /admin/* route
app.get('/admin/*', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/admin/index.html'));
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 Handler — When someone requests a route that doesn't exist
app.use((_req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found. Check the API documentation.',
    });
});

// Global Error Handler — Catches all unhandled errors
// Express requires exactly 4 parameters to recognize this as error middleware
app.use((err, _req, res, _next) => {
    console.error('Server Error:', err.message);

    // Don't leak error details in production
    const isDev = process.env.NODE_ENV === 'development';

    res.status(err.status || 500).json({
        success: false,
        message: isDev ? err.message : 'Internal server error',
        ...(isDev && { stack: err.stack }), // Only show stack trace in development
    });
});

// ============================================
// START THE SERVER
// ============================================

const PORT = process.env.PORT || 3000;

// Only start listening if this file is run directly (not imported for testing)
if (process.env.NODE_ENV !== 'test') {
    app.listen(PORT, () => {
        console.log('============================================');
        console.log('  Zippa Logistics API Server');
        console.log('============================================');
        console.log(`  Server: http://localhost:${PORT}`);
        console.log(`  Health: http://localhost:${PORT}/api/health`);
        console.log(`  Env:    ${process.env.NODE_ENV || 'development'}`);
        console.log('============================================');
    });
}

// Export app for testing
module.exports = app;
