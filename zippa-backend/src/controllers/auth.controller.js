// ============================================
// 🎓 AUTHENTICATION CONTROLLER (auth.controller.js)
//
// WHAT IS A CONTROLLER?
// A controller contains the "business logic" — the actual
// code that processes requests and sends responses.
// 
// Route → Controller flow:
// 1. User sends POST /api/auth/register
// 2. Express matches it to the auth route
// 3. The route calls the register() controller function
// 4. register() validates data, creates user, returns response
//
// This controller handles:
// - register: Create a new user account
// - login: Authenticate and get tokens
// - refreshToken: Get a new access token using refresh token
// ============================================

const bcrypt = require('bcryptjs');      // For hashing passwords
const jwt = require('jsonwebtoken');      // For creating JWT tokens
const db = require('../config/database');

// ============================================
// HELPER: Generate JWT Tokens
// ============================================

// Creates an access token (short-lived, used for API requests)
const generateAccessToken = (user) => {
    return jwt.sign(
        {
            userId: user.id,
            role: user.role,
            email: user.email,
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
        // Token expires in 1 hour by default
        // After that, the user needs to use their refresh token
    );
};

// Creates a refresh token (long-lived, used to get new access tokens)
const generateRefreshToken = (user) => {
    return jwt.sign(
        { userId: user.id },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
        // Refresh token lasts 7 days
    );
};

// ============================================
// CONTROLLER: register
// POST /api/auth/register
// Creates a new user account with a selected role.
// ============================================
const register = async (req, res) => {
    try {
        // Step 1: Extract data from request body
        // When the Flutter app sends JSON, it arrives in req.body
        const { email, phone, password, fullName, role } = req.body;

        // Step 2: Validate required fields
        // We check these on the server even if the app also validates
        // NEVER trust the client — always validate on the server!
        if (!phone || !password || !fullName) {
            return res.status(400).json({
                success: false,
                message: 'Phone number, password, and full name are required.',
            });
        }

        // Validate role
        const validRoles = ['customer', 'rider', 'vendor'];
        const userRole = role || 'customer'; // Default to customer
        if (!validRoles.includes(userRole)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid role. Must be: customer, rider, or vendor.',
            });
        }

        // Validate password strength
        if (password.length < 8) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 8 characters long.',
            });
        }

        // Step 3: Check if phone number already exists
        const existingPhone = await db.query(
            'SELECT id FROM users WHERE phone = $1',
            [phone]
        );
        if (existingPhone.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'An account with this phone number already exists.',
            });
            // 409 = Conflict (resource already exists)
        }

        // Check if email already exists (if provided)
        if (email) {
            const existingEmail = await db.query(
                'SELECT id FROM users WHERE email = $1',
                [email]
            );
            if (existingEmail.rows.length > 0) {
                return res.status(409).json({
                    success: false,
                    message: 'An account with this email already exists.',
                });
            }
        }

        // Step 4: Hash the password
        // NEVER store passwords in plain text!
        // bcrypt.hash() scrambles the password so it can't be reversed.
        // The '12' is the "salt rounds" — higher = more secure but slower.
        // 12 is a good balance between security and performance.
        const passwordHash = await bcrypt.hash(password, 12);

        // Step 5: Insert the new user into the database
        const result = await db.query(
            `INSERT INTO users (email, phone, password_hash, full_name, role)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, email, phone, full_name, role, kyc_status, created_at`,
            [email || null, phone, passwordHash, fullName, userRole]
        );
        // RETURNING = gives us back the created row (so we don't need a second query)

        const newUser = result.rows[0];

        // Step 6: Create a wallet for the user
        await db.query(
            'INSERT INTO wallets (user_id) VALUES ($1)',
            [newUser.id]
        );

        // Step 7: Create a user profile record
        await db.query(
            'INSERT INTO user_profiles (user_id) VALUES ($1)',
            [newUser.id]
        );

        // Step 8: Generate tokens
        const accessToken = generateAccessToken(newUser);
        const refreshToken = generateRefreshToken(newUser);

        // Store refresh token in database (for security)
        const refreshExpiry = new Date();
        refreshExpiry.setDate(refreshExpiry.getDate() + 7); // 7 days from now
        await db.query(
            'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
            [newUser.id, refreshToken, refreshExpiry]
        );

        // Step 9: Send success response
        // 201 = Created (new resource was successfully created)
        res.status(201).json({
            success: true,
            message: `Welcome to Zippa, ${fullName}! Account created successfully.`,
            data: {
                user: {
                    id: newUser.id,
                    email: newUser.email,
                    phone: newUser.phone,
                    fullName: newUser.full_name,
                    role: newUser.role,
                    kycStatus: newUser.kyc_status,
                },
                tokens: {
                    accessToken,
                    refreshToken,
                    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
                },
            },
        });

        console.log(`✅ New ${userRole} registered: ${fullName} (${phone})`);

    } catch (err) {
        console.error('Registration error:', err);
        res.status(500).json({
            success: false,
            message: 'Registration failed. Please try again.',
        });
    }
};

// ============================================
// CONTROLLER: login
// POST /api/auth/login
// Authenticates a user and returns JWT tokens.
// ============================================
const login = async (req, res) => {
    try {
        const { phone, email, password } = req.body;

        // Step 1: Validate input
        if ((!phone && !email) || !password) {
            return res.status(400).json({
                success: false,
                message: 'Phone number (or email) and password are required.',
            });
        }

        // Step 2: Find the user by phone or email
        let result;
        if (phone) {
            result = await db.query(
                'SELECT * FROM users WHERE phone = $1',
                [phone]
            );
        } else {
            result = await db.query(
                'SELECT * FROM users WHERE email = $1',
                [email]
            );
        }

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials. No account found with this phone/email.',
            });
            // 401 = Unauthorized
            // SECURITY TIP: Don't say "wrong password" — that tells hackers
            // the account exists. Say "invalid credentials" instead.
        }

        const user = result.rows[0];

        // Step 3: Check if account is active
        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                message: 'Account is deactivated. Please contact support.',
            });
        }

        // Step 4: Verify password
        // bcrypt.compare() hashes the input and compares it to the stored hash
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials. Please check your password.',
            });
        }

        // Step 5: Generate new tokens
        const accessToken = generateAccessToken(user);
        const refreshToken = generateRefreshToken(user);

        // Store refresh token
        const refreshExpiry = new Date();
        refreshExpiry.setDate(refreshExpiry.getDate() + 7);
        await db.query(
            'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
            [user.id, refreshToken, refreshExpiry]
        );

        // Step 6: Update last login timestamp
        await db.query(
            'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1',
            [user.id]
        );

        // Step 7: Send success response
        res.status(200).json({
            success: true,
            message: `Welcome back, ${user.full_name}!`,
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    phone: user.phone,
                    fullName: user.full_name,
                    role: user.role,
                    kycStatus: user.kyc_status,
                    isOnline: user.is_online,
                },
                tokens: {
                    accessToken,
                    refreshToken,
                    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
                },
            },
        });

        console.log(`✅ User logged in: ${user.full_name} (${user.role})`);

    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({
            success: false,
            message: 'Login failed. Please try again.',
        });
    }
};

// ============================================
// CONTROLLER: refreshToken
// POST /api/auth/refresh-token
// Uses a refresh token to get a new access token.
//
// WHY DO WE NEED THIS?
// Access tokens expire quickly (1 hour) for security.
// Instead of asking the user to type their password every hour,
// the app automatically uses the refresh token to get a new
// access token in the background. The user never notices!
// ============================================
const refreshToken = async (req, res) => {
    try {
        const { refreshToken: token } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token is required.',
            });
        }

        // Step 1: Verify the refresh token
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
        } catch (_err) {
            return res.status(401).json({
                success: false,
                message: 'Invalid or expired refresh token. Please log in again.',
            });
        }

        // Step 2: Check if the refresh token exists in database
        // (It could have been revoked/deleted)
        const storedToken = await db.query(
            'SELECT * FROM refresh_tokens WHERE token = $1 AND user_id = $2 AND is_revoked = false',
            [token, decoded.userId]
        );

        if (storedToken.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Refresh token not found or has been revoked.',
            });
        }

        // Step 3: Get the user
        const userResult = await db.query(
            'SELECT id, email, phone, full_name, role, kyc_status FROM users WHERE id = $1 AND is_active = true',
            [decoded.userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'User not found or account deactivated.',
            });
        }

        const user = userResult.rows[0];

        // Step 4: Revoke the old refresh token (one-time use)
        await db.query(
            'UPDATE refresh_tokens SET is_revoked = true WHERE token = $1',
            [token]
        );

        // Step 5: Generate new token pair
        const newAccessToken = generateAccessToken(user);
        const newRefreshToken = generateRefreshToken(user);

        // Store new refresh token
        const refreshExpiry = new Date();
        refreshExpiry.setDate(refreshExpiry.getDate() + 7);
        await db.query(
            'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
            [user.id, newRefreshToken, refreshExpiry]
        );

        res.status(200).json({
            success: true,
            data: {
                tokens: {
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
                },
            },
        });

    } catch (err) {
        console.error('Refresh token error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to refresh token. Please log in again.',
        });
    }
};

module.exports = { register, login, refreshToken };
