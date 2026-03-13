const express = require('express');
const router = express.Router();

const { authenticate } = require('../middleware/auth.middleware');
const { getProfile, updateProfile, changePassword, toggleOnline, updateLocation, updateFcmToken, submitKYC, getKYCStatus, kycUpload } = require('../controllers/user.controller');

// All routes below require authentication
router.get('/profile', authenticate, getProfile),
router.put('/profile', authenticate, updateProfile),
router.put('/change-password', authenticate, changePassword),
router.post('/toggle-online', authenticate, toggleOnline),
router.put('/location', authenticate, updateLocation),
router.put('/fcm-token', authenticate, updateFcmToken),

// KYC Routes
router.post('/kyc', authenticate, kycUpload.single('document'), submitKYC);
router.get('/kyc', authenticate, getKYCStatus);

module.exports = router;

