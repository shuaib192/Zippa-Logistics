// ============================================
// 🎓 AUTHENTICATION MIDDLEWARE (auth.middleware.js)
//
// WHAT IS MIDDLEWARE?
// Middleware is a function that runs BETWEEN receiving
// a request and sending a response. It sits in the "middle".
//
// This file has two middlewares:
// 1. authenticate — Checks if the user is logged in (has valid token)
// 2. authorize    — Checks if the user has the right ROLE
//
// HOW JWT AUTHENTICATION WORKS:
// 1. User logs in → server creates a JWT (JSON Web Token)
// 2. JWT is like a digital passport — contains user ID and role
// 3. App stores the JWT and sends it with every request
// 4. This middleware checks if the JWT is valid
// 5. If valid → request continues to the route handler
// 6. If invalid → 401 Unauthorized error
//
// WHAT IS A JWT?
// JWT = JSON Web Token = a signed string that looks like:
// "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiIxMjMifQ.signature"
// It has 3 parts separated by dots: Header.Payload.Signature
// The server can verify it wasn't tampered with using the secret key.
// ============================================

const jwt = require('jsonwebtoken');    // Library for creating/verifying JWTs
const db = require('../config/database'); // Database connection

// ============================================
// MIDDLEWARE 1: authenticate
// Verifies the JWT token is valid and loads the user
// ============================================
const authenticate = async (req, res, next) => {
    try {
        // Step 1: Get the token from the request header
        // The app sends it as: Authorization: Bearer <token>
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'Access denied. No authentication token provided.',
                hint: 'Include a valid JWT in the Authorization header: "Bearer <token>"',
            });
        }

        // Extract just the token part (remove "Bearer " prefix)
        const token = authHeader.split(' ')[1];

        // Step 2: Verify the token using our secret key
        // jwt.verify() will throw an error if the token is:
        // - Expired (past its expiration time)
        // - Invalid (tampered with or wrong secret)
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        // 'decoded' now contains: { userId: "...", role: "customer", iat: ..., exp: ... }

        // Step 3: Check if the user still exists in the database
        // (They might have been deleted or deactivated since the token was issued)
        const result = await db.query(
            'SELECT id, email, phone, full_name, role, kyc_status, is_active FROM users WHERE id = $1',
            [decoded.userId]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'User account not found. Token may be invalid.',
            });
        }

        const user = result.rows[0];

        // Step 4: Check if the account is active
        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                message: 'Account has been deactivated. Contact support.',
            });
        }

        // Step 5: Attach user info to the request object
        // Now any route handler can access req.user to know who's making the request
        req.user = {
            id: user.id,
            email: user.email,
            phone: user.phone,
            fullName: user.full_name,
            role: user.role,
            kycStatus: user.kyc_status,
        };

        // Move to the next middleware or route handler
        next();

    } catch (err) {
        // Handle specific JWT errors with clear messages
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token has expired. Please log in again or use refresh token.',
                code: 'TOKEN_EXPIRED',
            });
        }

        if (err.name === 'JsonWebTokenError') {
            return res.status(401).json({
                success: false,
                message: 'Invalid token. Please log in again.',
                code: 'INVALID_TOKEN',
            });
        }

        // Unknown error
        console.error('Auth middleware error:', err);
        return res.status(500).json({
            success: false,
            message: 'Authentication error. Please try again.',
        });
    }
};

// ============================================
// MIDDLEWARE 2: authorize(...roles)
// Checks if the authenticated user has the required role.
// 
// USAGE:
//   router.get('/admin/users', authenticate, authorize('admin'), handler)
//   router.get('/rider/orders', authenticate, authorize('rider', 'admin'), handler)
//
// This is a "higher-order function" — a function that returns a function.
// The outer function takes the allowed roles, the inner function
// is the actual middleware that Express calls.
// ============================================
const authorize = (...roles) => {
    return (req, res, next) => {
        // req.user was set by the authenticate middleware above
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required before authorization.',
            });
        }

        // Check if the user's role is in the allowed roles list
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. This endpoint requires one of these roles: ${roles.join(', ')}. Your role: ${req.user.role}`,
            });
        }

        // User has the right role, continue
        next();
    };
};

module.exports = { authenticate, authorize };
