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
const { register, login, refreshToken } = require('../controllers/auth.controller');

// POST /api/auth/register — Create a new account
// No authentication needed (the user isn't logged in yet!)
router.post('/register', register);

// POST /api/auth/login — Log in to get tokens
router.post('/login', login);

// POST /api/auth/refresh-token — Get new access token
router.post('/refresh-token', refreshToken);

module.exports = router;
