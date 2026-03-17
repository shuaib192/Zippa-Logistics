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

// TEMPORARY: Low-level Network Diagnostic (remove after debugging)
router.get('/net-test', async (req, res) => {
    const net = require('net');
    const tls = require('tls');
    
    const results = { timestamp: new Date().toISOString() };
    
    const checkPort = (port, host, useTls) => {
        return new Promise((resolve) => {
            const result = { port, host, status: 'pending', timeMs: 0 };
            const start = Date.now();
            
            const timer = setTimeout(() => {
                if (!result.done) {
                    result.done = true;
                    result.status = 'timeout (10s)';
                    if (socket) socket.destroy();
                    resolve(result);
                }
            }, 10000);

            const options = { host, port, family: 4 }; // Force IPv4
            const socket = useTls ? tls.connect(options) : net.connect(options);

            socket.on('secureConnect', () => {
                result.status = 'tls_connected';
                result.timeMs = Date.now() - start;
                result.done = true;
                clearTimeout(timer);
                socket.end();
                resolve(result);
            });

            socket.on('connect', () => {
                if (!useTls) {
                    result.status = 'connected';
                    result.timeMs = Date.now() - start;
                    result.done = true;
                    clearTimeout(timer);
                    socket.end();
                    resolve(result);
                }
            });

            socket.on('error', (err) => {
                if (!result.done) {
                    result.status = 'error: ' + err.message;
                    result.done = true;
                    clearTimeout(timer);
                    resolve(result);
                }
            });
        });
    };

    try {
        results.port465_tls = await checkPort(465, 'smtp.gmail.com', true);
        results.port587_plain = await checkPort(587, 'smtp.gmail.com', false);
        res.json({ success: true, results });
    } catch (err) {
        res.json({ success: false, error: err.message });
    }
});

module.exports = router;
