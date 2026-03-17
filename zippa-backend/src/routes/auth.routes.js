// ============================================
// 🎓 AUTH ROUTES (auth.routes.js)
//
// WHAT IS A ROUTE?
// A route maps a URL + HTTP method to a controller function.
// It's like a menu at a restaurant:
//   POST /api/auth/register  → "I want to create an account"
//   POST /api/auth/login     → "I want to log in"
//
// HTTP METHODS:
//   GET    = Read data (like viewing a page)
//   POST   = Create something new (like submitting a form)
//   PUT    = Update existing data
//   DELETE = Remove data
//
// We use Express Router to group related routes together.
// ============================================

const express = require('express');
const router = express.Router();

// Import controller functions
const { register, login, refreshToken, verifyEmail, resendOTP, forgotPassword, resetPassword } = require('../controllers/auth.controller');

// POST /api/auth/register — Create a new account
router.post('/register', register);

// POST /api/auth/verify-email — Verify email with OTP
router.post('/verify-email', verifyEmail);

// POST /api/auth/resend-otp — Resend OTP code
router.post('/resend-otp', resendOTP);

// POST /api/auth/login — Log in to get tokens
router.post('/login', login);

// POST /api/auth/refresh-token — Get new access token
router.post('/refresh-token', refreshToken);

// POST /api/auth/forgot-password — Request reset code
router.post('/forgot-password', forgotPassword);

// POST /api/auth/reset-password — Reset password with code
router.post('/reset-password', resetPassword);

// TEMPORARY: Diagnostic email test endpoint (remove after debugging)
router.get('/test-email', async (req, res) => {
    const nodemailer = require('nodemailer');
    const email = process.env.SMTP_EMAIL;
    const pass = process.env.SMTP_APP_PASSWORD;
    
    const diag = {
        timestamp: new Date().toISOString(),
        smtp_email: email || '❌ NOT SET',
        smtp_pass_length: pass ? pass.length : 0,
        env_node_version: process.version,
    };

    console.log('[DEBUG-EMAIL] Starting diagnostic test...');

    try {
        const transporter = nodemailer.createTransport({
            host: 'smtp.gmail.com',
            port: 587,
            secure: false,
            auth: { user: email, pass: pass },
            connectionTimeout: 10000, // 10 seconds timeout for connection
            greetingTimeout: 10000,   // 10 seconds timeout for greeting
            socketTimeout: 10000,     // 10 seconds timeout for reading
        });
        
        console.log('[DEBUG-EMAIL] Verifying connection...');
        diag.step = 'verifying';
        try {
            await transporter.verify();
            diag.connection = '✅ SMTP connected';
            console.log('[DEBUG-EMAIL] Connection verified.');
        } catch (vErr) {
            console.error('[DEBUG-EMAIL] Verification failed:', vErr.message);
            diag.connection_error = vErr.message;
            diag.connection_code = vErr.code;
            return res.json({ success: false, diag });
        }
        
        console.log('[DEBUG-EMAIL] Sending test email...');
        diag.step = 'sending';
        const info = await transporter.sendMail({
            from: `"Zippa Test" <${email}>`,
            to: email,
            subject: 'Render Email Test - ' + new Date().toISOString(),
            html: '<h1>✅ Render email works!</h1>',
        });
        
        diag.send = '✅ SENT';
        diag.messageId = info.messageId;
        console.log('[DEBUG-EMAIL] Email sent:', info.messageId);
        
        res.json({ success: true, diag });
    } catch (err) {
        console.error('[DEBUG-EMAIL] unexpected error:', err.message);
        diag.error = err.message;
        diag.code = err.code;
        res.json({ success: false, diag });
    }
});


