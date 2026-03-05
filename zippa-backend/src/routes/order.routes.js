// ============================================
// ORDER ROUTES (order.routes.js)
// ============================================

const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth.middleware');
const {
    estimateFare,
    createOrder,
    getOrders,
    getOrderById,
    updateOrderStatus,
} = require('../controllers/order.controller');

// All order routes require authentication
router.use(authenticate);

// POST /api/orders/estimate   — Get a price quote (customers + vendors)
router.post('/estimate', authorize('customer', 'vendor'), estimateFare);

// POST /api/orders            — Place a new order (customers + vendors)
router.post('/', authorize('customer', 'vendor'), createOrder);

// GET  /api/orders            — List orders (filtered by role)
router.get('/', getOrders);

// GET  /api/orders/:id        — Get single order details
router.get('/:id', getOrderById);

// PUT  /api/orders/:id/status — Update delivery status (riders)
router.put('/:id/status', authorize('rider', 'admin'), updateOrderStatus);

module.exports = router;
