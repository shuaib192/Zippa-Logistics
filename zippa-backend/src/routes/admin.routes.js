const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

// All routes require authentication and admin role
router.use(authenticate);
router.use(authorize('admin'));


// Dashboard Stats
router.get('/stats', adminController.getDashboardStats);

// User Management
router.get('/users', adminController.getAllUsers);
router.put('/users/:id/kyc', adminController.updateKYCStatus);

// Order Management
router.get('/orders', adminController.getAllOrders);

// Settings
router.get('/settings', adminController.getSettings);
router.put('/settings', adminController.updateSettings);

// Notifications
router.post('/notifications/broadcast', adminController.broadcastNotification);

module.exports = router;
