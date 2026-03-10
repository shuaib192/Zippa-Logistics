// ============================================
// 🎓 USER ROUTES (user.routes.js)
//
// These routes require authentication.
// Notice how we import 'authenticate' and use it
// as middleware BEFORE the controller function.
// 
// The flow is:
// Request → authenticate (check JWT) → controller (do the work)
// ============================================

const express = require('express');
const router = express.Router();

const { authenticate } = require('../middleware/auth.middleware');
const { getProfile, updateProfile, changePassword, toggleOnline, updateLocation, updateFcmToken } = require('../controllers/user.controller');

// All routes below require authentication
// GET /api/users/profile — View your profile
router.get('/profile', authenticate, getProfile),

// PUT /api/users/profile — Update your profile
router.put('/profile', authenticate, updateProfile),

// PUT /api/users/change-password — Change password
router.put('/change-password', authenticate, changePassword),

// POST /api/users/toggle-online — Toggle rider online status
router.post('/toggle-online', authenticate, toggleOnline),

// PUT /api/users/location — Update rider current coordinates
router.put('/location', authenticate, updateLocation),

// PUT /api/users/fcm-token — Update user FCM token
router.put('/fcm-token', authenticate, updateFcmToken),

module.exports = router;
