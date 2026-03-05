// ============================================
// 🎓 ORDERS CONTROLLER (order.controller.js)
//
// This handles ALL order-related operations:
// 1. createOrder  - Customer places a new delivery
// 2. estimateFare - Calculate delivery cost before placing
// 3. getOrders    - List orders (filtered by role)
// 4. getOrderById - View a specific order
// 5. updateStatus - Rider updates delivery status
//
// FARE ESTIMATION LOGIC:
// We use the Haversine formula to calculate distance
// between two GPS coordinates, then apply a rate per km.
// ============================================

const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

// ============================================
// HELPER: Haversine formula
// Calculates the straight-line distance (km)
// between two lat/lng coordinate pairs.
// ============================================
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Earth radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

// ============================================
// HELPER: Calculate fare
// Base rate: ₦500 base + ₦150/km
// Package size multipliers apply on top.
// ============================================
const calculateFare = (distanceKm, packageSize = 'small') => {
    const BASE_FARE = 500;   // flat starting fee (covers first 1 km)
    const PER_KM = 150;      // cost per additional km

    const sizeMultipliers = {
        small: 1.0,
        medium: 1.3,
        large: 1.6,
        extra: 2.0,
    };

    const multiplier = sizeMultipliers[packageSize] || 1.0;
    const distanceFare = Math.max(0, distanceKm - 1) * PER_KM; // first km already in base
    const rawFare = (BASE_FARE + distanceFare) * multiplier;

    return {
        baseFare: BASE_FARE,
        distanceFare: Math.round(distanceFare),
        subtotal: Math.round(rawFare),
        platformFee: Math.round(rawFare * 0.10), // 10% platform cut
        total: Math.round(rawFare * 1.10),       // customer pays
        riderEarning: Math.round(rawFare * 0.70), // rider gets 70%
        distanceKm: Math.round(distanceKm * 10) / 10,
    };
};

// ============================================
// CONTROLLER: estimateFare
// POST /api/orders/estimate
// Gives the customer a price BEFORE placing the order.
// ============================================
const estimateFare = async (req, res) => {
    try {
        const {
            pickupLat, pickupLng,
            dropoffLat, dropoffLng,
            packageSize,
        } = req.body;

        if (!pickupLat || !pickupLng || !dropoffLat || !dropoffLng) {
            return res.status(400).json({
                success: false,
                message: 'Pickup and dropoff coordinates are required.',
            });
        }

        const distanceKm = calculateDistance(
            parseFloat(pickupLat), parseFloat(pickupLng),
            parseFloat(dropoffLat), parseFloat(dropoffLng),
        );

        const fare = calculateFare(distanceKm, packageSize);

        res.status(200).json({
            success: true,
            data: {
                ...fare,
                currency: 'NGN',
                estimatedDuration: `${Math.round(distanceKm / 30 * 60)} mins`, // ~30km/h avg
            },
        });

    } catch (err) {
        console.error('Fare estimation error:', err);
        res.status(500).json({ success: false, message: 'Failed to estimate fare.' });
    }
};

// ============================================
// CONTROLLER: createOrder
// POST /api/orders
// Creates a new delivery order.
// ============================================
const createOrder = async (req, res) => {
    try {
        const {
            pickupAddress, pickupLat, pickupLng,
            dropoffAddress, dropoffLat, dropoffLng,
            recipientName, recipientPhone,
            packageSize, packageDescription,
            paymentMethod,
        } = req.body;

        // Validate required fields
        const required = { pickupAddress, dropoffAddress, recipientName, recipientPhone, packageSize };
        for (const [field, value] of Object.entries(required)) {
            if (!value) {
                return res.status(400).json({
                    success: false,
                    message: `${field} is required.`,
                });
            }
        }

        // Calculate distance and fare
        const distanceKm = (pickupLat && dropoffLat)
            ? calculateDistance(parseFloat(pickupLat), parseFloat(pickupLng), parseFloat(dropoffLat), parseFloat(dropoffLng))
            : 5; // default fallback

        const fare = calculateFare(distanceKm, packageSize);

        // Generate unique order number: ZLP-YYYYMMDD-XXXX
        const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const randomPart = Math.random().toString(36).substring(2, 6).toUpperCase();
        const orderNumber = `ZLP-${datePart}-${randomPart}`;

        // Create the order
        const result = await db.query(
            `INSERT INTO orders (
                order_number, customer_id, vendor_id,
                pickup_address, pickup_lat, pickup_lng,
                dropoff_address, dropoff_lat, dropoff_lng,
                recipient_name, recipient_phone,
                package_size, package_description,
                base_fare, distance_fare, platform_fee, total_fare, rider_earning,
                distance_km, payment_method, status
            ) VALUES (
                $1, $2, $3,
                $4, $5, $6,
                $7, $8, $9,
                $10, $11,
                $12, $13,
                $14, $15, $16, $17, $18,
                $19, $20, 'pending'
            ) RETURNING *`,
            [
                orderNumber,
                req.user.role === 'customer' ? req.user.id : null,
                req.user.role === 'vendor' ? req.user.id : null,
                pickupAddress, pickupLat || null, pickupLng || null,
                dropoffAddress, dropoffLat || null, dropoffLng || null,
                recipientName, recipientPhone,
                packageSize, packageDescription || null,
                fare.baseFare, fare.distanceFare, fare.platformFee, fare.total, fare.riderEarning,
                fare.distanceKm, paymentMethod || 'wallet',
            ],
        );

        const order = result.rows[0];

        res.status(201).json({
            success: true,
            message: 'Order placed successfully. Searching for a rider...',
            data: {
                orderId: order.id,
                orderNumber: order.order_number,
                status: order.status,
                fare: {
                    total: order.total_fare,
                    breakdown: {
                        base: order.base_fare,
                        distance: order.distance_fare,
                        platformFee: order.platform_fee,
                    },
                },
                estimatedDistance: `${order.distance_km} km`,
            },
        });

    } catch (err) {
        console.error('Create order error:', err);
        res.status(500).json({ success: false, message: 'Failed to create order. Please try again.' });
    }
};

// ============================================
// CONTROLLER: getOrders
// GET /api/orders
// Returns orders filtered by the user's role.
// - Customer → their own orders
// - Rider    → assigned orders + pending ones nearby
// - Vendor   → all orders they created
// ============================================
const getOrders = async (req, res) => {
    try {
        const { status, limit = 20, offset = 0 } = req.query;
        const { id: userId, role } = req.user;

        let query, params;

        if (role === 'customer') {
            query = `SELECT o.*, 
                u.full_name as rider_name, u.phone as rider_phone
                FROM orders o
                LEFT JOIN users u ON u.id = o.rider_id
                WHERE o.customer_id = $1
                ${status ? 'AND o.status = $2' : ''}
                ORDER BY o.created_at DESC
                LIMIT $${status ? 3 : 2} OFFSET $${status ? 4 : 3}`;
            params = status ? [userId, status, limit, offset] : [userId, limit, offset];

        } else if (role === 'rider') {
            // Riders see their assigned + all pending (available to pick up)
            query = `SELECT o.*,
                u.full_name as customer_name, u.phone as customer_phone
                FROM orders o
                LEFT JOIN users u ON u.id = o.customer_id
                WHERE (o.rider_id = $1 OR (o.status = 'pending' AND o.rider_id IS NULL))
                ${status ? 'AND o.status = $2' : ''}
                ORDER BY o.created_at DESC
                LIMIT $${status ? 3 : 2} OFFSET $${status ? 4 : 3}`;
            params = status ? [userId, status, limit, offset] : [userId, limit, offset];

        } else if (role === 'vendor') {
            query = `SELECT o.*,
                u.full_name as rider_name
                FROM orders o
                LEFT JOIN users u ON u.id = o.rider_id
                WHERE o.vendor_id = $1
                ${status ? 'AND o.status = $2' : ''}
                ORDER BY o.created_at DESC
                LIMIT $${status ? 3 : 2} OFFSET $${status ? 4 : 3}`;
            params = status ? [userId, status, limit, offset] : [userId, limit, offset];
        } else {
            return res.status(403).json({ success: false, message: 'Access denied.' });
        }

        const result = await db.query(query, params);

        res.status(200).json({
            success: true,
            data: {
                orders: result.rows,
                count: result.rows.length,
                hasMore: result.rows.length === parseInt(limit),
            },
        });

    } catch (err) {
        console.error('Get orders error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve orders.' });
    }
};

// ============================================
// CONTROLLER: getOrderById
// GET /api/orders/:id
// Returns full details of a single order.
// ============================================
const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;
        const { id: userId, role } = req.user;

        const result = await db.query(
            `SELECT o.*,
                c.full_name as customer_name, c.phone as customer_phone,
                r.full_name as rider_name, r.phone as rider_phone
            FROM orders o
            LEFT JOIN users c ON c.id = o.customer_id
            LEFT JOIN users r ON r.id = o.rider_id
            WHERE o.id = $1 OR o.order_number = $1`,
            [id],
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Order not found.' });
        }

        const order = result.rows[0];

        // Security: only involved parties can view the order
        const canView =
            order.customer_id === userId ||
            order.rider_id === userId ||
            order.vendor_id === userId ||
            role === 'admin';

        if (!canView) {
            return res.status(403).json({ success: false, message: 'Access denied.' });
        }

        res.status(200).json({ success: true, data: order });

    } catch (err) {
        console.error('Get order by ID error:', err);
        res.status(500).json({ success: false, message: 'Failed to retrieve order.' });
    }
};

// ============================================
// CONTROLLER: updateOrderStatus
// PUT /api/orders/:id/status
// Allows riders to update delivery status.
// Status flow: pending → accepted → picked_up → delivered
// ============================================
const updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const { id: userId, role } = req.user;

        const validStatuses = ['accepted', 'arrived', 'picked_up', 'delivered', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
            });
        }

        // Fetch the order
        const orderResult = await db.query('SELECT * FROM orders WHERE id = $1 OR order_number = $1', [id]);
        if (orderResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Order not found.' });
        }

        const order = orderResult.rows[0];

        // Verify authorization
        if (role === 'rider' && order.rider_id !== userId) {
            // Rider accepting a new order (assigned to them)
            if (status === 'accepted' && order.status === 'pending') {
                await db.query(
                    `UPDATE orders SET status = $1, rider_id = $2, accepted_at = CURRENT_TIMESTAMP WHERE id = $3`,
                    ['accepted', userId, order.id],
                );
            } else {
                return res.status(403).json({ success: false, message: 'This order is not assigned to you.' });
            }
        } else {
            // Build update query with timestamps
            const timestamps = {
                accepted: 'accepted_at',
                picked_up: 'picked_up_at',
                delivered: 'delivered_at',
            };

            const timestampCol = timestamps[status];
            const updateQuery = timestampCol
                ? `UPDATE orders SET status = $1, ${timestampCol} = CURRENT_TIMESTAMP WHERE id = $2`
                : 'UPDATE orders SET status = $1 WHERE id = $2';

            await db.query(updateQuery, [status, order.id]);
        }

        res.status(200).json({
            success: true,
            message: `Order status updated to ${status}.`,
            data: { orderId: order.id, status },
        });

    } catch (err) {
        console.error('Update order status error:', err);
        res.status(500).json({ success: false, message: 'Failed to update order status.' });
    }
};

module.exports = { estimateFare, createOrder, getOrders, getOrderById, updateOrderStatus };
