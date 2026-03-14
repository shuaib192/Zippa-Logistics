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
const { calculateFare } = require('../utils/fare_calculator');
const { createNotification } = require('./notification.controller');
const NotificationService = require('../services/notification.service');


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
// CONTROLLER: estimateFare
// POST /api/orders/estimate
// Gives the customer a price BEFORE placing the order.
// ============================================
const estimateFare = async (req, res) => {
    try {
        const {
            pickup_address, pickup_lat, pickup_lng,
            dropoff_address, dropoff_lat, dropoff_lng,
            package_type, package_size,
        } = req.body;

        if (pickup_lat === undefined || pickup_lng === undefined || dropoff_lat === undefined || dropoff_lng === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Pickup and dropoff coordinates are required.',
            });
        }

        const distanceKm = calculateDistance(
            parseFloat(pickup_lat), parseFloat(pickup_lng),
            parseFloat(dropoff_lat), parseFloat(dropoff_lng),
        );

        const fare = await calculateFare(distanceKm, package_size);

        res.status(200).json({
            success: true,
            data: {
                ...fare,
                pickup_address,
                dropoff_address,
                package_type,
                package_size,
                distance: distanceKm,
                currency: 'NGN',
                estimatedDuration: `${Math.round(distanceKm / 30 * 60)} mins`,
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
    const client = await db.connect();
    try {
        const {
            pickup_address, pickup_lat, pickup_lng,
            dropoff_address, dropoff_lat, dropoff_lng,
            recipient_name, recipient_phone,
            package_type, package_size, package_description,
            payment_method, vendor_id, item_price = 0,
            customer_notes
        } = req.body;

        // Validate required fields
        const required = { pickup_address, dropoff_address, recipient_name, recipient_phone, package_type, package_size };
        for (const [field, value] of Object.entries(required)) {
            if (!value) {
                return res.status(400).json({
                    success: false,
                    message: `${field} is required.`,
                });
            }
        }

        const distanceKm = (pickup_lat && dropoff_lat)
            ? calculateDistance(parseFloat(pickup_lat), parseFloat(pickup_lng), parseFloat(dropoff_lat), parseFloat(dropoff_lng))
            : 5; // default fallback

        const fare = await calculateFare(distanceKm, package_size);
        const totalAmount = parseFloat(fare.total_fare) + parseFloat(item_price);

        // Generate unique order number: ZLP-YYYYMMDD-XXXX
        const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const randomPart = Math.random().toString(36).substring(2, 6).toUpperCase();
        const orderNumber = `ZLP-${datePart}-${randomPart}`;

        await client.query('BEGIN');

        // Check Wallet Balance if payment method is wallet
        if (payment_method !== 'cash') {
            const walletRes = await client.query('SELECT balance FROM wallets WHERE user_id = $1', [req.user.id]);
            if (walletRes.rows.length === 0 || parseFloat(walletRes.rows[0].balance) < totalAmount) {
                await client.query('ROLLBACK');
                return res.status(400).json({ success: false, message: 'Insufficient wallet balance.' });
            }

            // Debit Wallet
            const reference = `ORD-${orderNumber}`;
            const oldBalance = parseFloat(walletRes.rows[0].balance);
            const newBalance = oldBalance - totalAmount;

            await client.query('UPDATE wallets SET balance = $1 WHERE user_id = $2', [newBalance, req.user.id]);
            await client.query(
                `INSERT INTO wallet_transactions (wallet_id, type, amount, balance_before, balance_after, reference, description, status) 
                 SELECT id, 'debit', $1, $2, $3, $4, $5, 'completed' FROM wallets WHERE user_id = $6`,
                [totalAmount, oldBalance, newBalance, reference, `Escrow payment for order (Item: ${item_price}, Delivery: ${fare.total_fare})`, req.user.id]
            );

            // Increment Vendor Pending Balance (if applicable)
            if (vendor_id && parseFloat(item_price) > 0) {
                await client.query(
                    'UPDATE wallets SET pending_balance = pending_balance + $1 WHERE user_id = $2',
                    [item_price, vendor_id]
                );
            }
        }

        // Create the order
        const result = await client.query(
            `INSERT INTO orders (
                order_number, customer_id, vendor_id, item_price,
                pickup_address, pickup_latitude, pickup_longitude,
                dropoff_address, dropoff_latitude, dropoff_longitude,
                dropoff_contact_name, dropoff_contact_phone,
                package_type, package_size, package_description,
                base_fare, distance_fare, platform_fee, subtotal, total_fare, rider_earning,
                distance_km, payment_method, status, payment_status, customer_notes,
                is_marketplace
            ) VALUES (
                $1, $2, $3, $4,
                $5, $6, $7,
                $8, $9, $10,
                $11, $12,
                $13, $14, $15,
                $16, $17, $18, $19, $20, $21,
                $22, $23, 'pending', 'held', $24, $25
            ) RETURNING *, 
                pickup_latitude as pickup_lat, pickup_longitude as pickup_lng, 
                dropoff_latitude as dropoff_lat, dropoff_longitude as dropoff_lng,
                dropoff_contact_name as recipient_name, dropoff_contact_phone as recipient_phone`,
            [
                orderNumber,
                req.user.id, // Primary initiator
                vendor_id || (req.user.role === 'vendor' ? req.user.id : null),
                item_price,
                pickup_address, pickup_lat || null, pickup_lng || null,
                dropoff_address, dropoff_lat || null, dropoff_lng || null,
                recipient_name, recipient_phone,
                package_type, package_size, package_description || null,
                fare.base_fare, fare.distance_fare, fare.platform_fee, fare.subtotal, fare.total_fare, fare.rider_earning,
                fare.distance_km, payment_method || 'wallet',
                customer_notes || null,
                vendor_id ? true : false,
            ],
        );

        await client.query('COMMIT');

        const order = result.rows[0];

        // Create notification for customer
        await createNotification(
            order.customer_id, // Use order.customer_id as the recipient
            'Order Placed!',
            `Your order #${orderNumber} has been successfully placed and is pending rider acceptance.`,
            'order',
            order.id
        );

        // Broadcast to all Riders via FCM Topic
        NotificationService.sendToTopic('riders', {
            title: 'New Delivery Available!',
            body: `Package from ${pickup_address} to ${dropoff_address}. Tap to view.`,
            data: {
                type: 'new_order',
                related_id: order.id.toString()
            }
        });

        res.status(201).json({
            success: true,
            message: 'Order placed successfully. Searching for a rider...',
            order: order,
        });

    } catch (err) {
        if (client) await client.query('ROLLBACK');
        console.error('Create order error:', err);
        res.status(500).json({ success: false, message: 'Failed to create order. Please try again.' });
    } finally {
        if (client) client.release();
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
                o.pickup_latitude as pickup_lat, o.pickup_longitude as pickup_lng, 
                o.dropoff_latitude as dropoff_lat, o.dropoff_longitude as dropoff_lng,
                o.dropoff_contact_name as recipient_name, o.dropoff_contact_phone as recipient_phone,
                u.full_name as rider_name, u.phone as rider_phone,
                vp.business_name as vendor_name
                FROM orders o
                LEFT JOIN users u ON u.id = o.rider_id
                LEFT JOIN user_profiles vp ON vp.user_id = o.vendor_id
                WHERE o.customer_id = $1
                ${status ? 'AND o.status = $2' : ''}
                ORDER BY o.created_at DESC
                LIMIT $${status ? 3 : 2} OFFSET $${status ? 4 : 3}`;
            params = status ? [userId, status, limit, offset] : [userId, limit, offset];

        } else if (role === 'rider') {
            // Riders see their assigned + all pending (available to pick up)
            query = `SELECT o.*,
                o.pickup_latitude as pickup_lat, o.pickup_longitude as pickup_lng, 
                o.dropoff_latitude as dropoff_lat, o.dropoff_longitude as dropoff_lng,
                o.dropoff_contact_name as recipient_name, o.dropoff_contact_phone as recipient_phone,
                u.full_name as customer_name, u.phone as customer_phone,
                vp.business_name as vendor_name
                FROM orders o
                LEFT JOIN users u ON u.id = o.customer_id
                LEFT JOIN user_profiles vp ON vp.user_id = o.vendor_id
                WHERE (o.rider_id = $1 OR (o.status = 'pending' AND o.rider_id IS NULL))
                ${status ? 'AND o.status = $2' : ''}
                ORDER BY o.created_at DESC
                LIMIT $${status ? 3 : 2} OFFSET $${status ? 4 : 3}`;
            params = status ? [userId, status, limit, offset] : [userId, limit, offset];

        } else if (role === 'vendor') {
            query = `SELECT o.*,
                o.pickup_latitude as pickup_lat, o.pickup_longitude as pickup_lng, 
                o.dropoff_latitude as dropoff_lat, o.dropoff_longitude as dropoff_lng,
                o.dropoff_contact_name as recipient_name, o.dropoff_contact_phone as recipient_phone,
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
            orders: result.rows,
            count: result.rows.length,
            hasMore: result.rows.length === parseInt(limit),
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
        console.log(`[DEBUG] getOrderById: id=${id}, userId=${userId}, role=${role}`);

        const result = await db.query(
            `SELECT o.*,
                o.pickup_latitude as pickup_lat, o.pickup_longitude as pickup_lng, 
                o.dropoff_latitude as dropoff_lat, o.dropoff_longitude as dropoff_lng,
                o.dropoff_contact_name as recipient_name, o.dropoff_contact_phone as recipient_phone,
                c.full_name as customer_name, c.phone as customer_phone, c.avatar_url as customer_avatar,
                r.full_name as rider_name, r.phone as rider_phone, r.avatar_url as rider_avatar,
                vp.business_name as vendor_name,
                rp.current_latitude as rider_lat, rp.current_longitude as rider_lng,
                rp.last_location_update
            FROM orders o
            LEFT JOIN users c ON c.id = o.customer_id
            LEFT JOIN users r ON r.id = o.rider_id
            LEFT JOIN user_profiles rp ON rp.user_id = o.rider_id
            LEFT JOIN user_profiles vp ON vp.user_id = o.vendor_id
            WHERE o.id::text = $1 OR o.order_number = $1`,
            [id],
        );

        if (result.rows.length === 0) {
            console.warn(`[DEBUG] getOrderById: Order with ID/Number ${id} NOT FOUND in DB.`);
            return res.status(404).json({ success: false, message: 'Order not found.' });
        }

        const order = result.rows[0];

        // Security: only involved parties can view the order
        const canView =
            order.customer_id === userId ||
            order.rider_id === userId ||
            order.vendor_id === userId ||
            role === 'admin' ||
            (role === 'rider' && order.status === 'pending');

        if (!canView) {
            return res.status(403).json({ success: false, message: 'Access denied.' });
        }

        res.status(200).json({ success: true, order: order });

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

        // Fetch the order (Use ::text casting to allow comparison with order_number if id is not a UUID)
        const orderResult = await db.query('SELECT * FROM orders WHERE id::text = $1 OR order_number = $1', [id]);
        if (orderResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Order not found.' });
        }

        const order = orderResult.rows[0];

        // Verify authorization
        const isRiderOwner = order.rider_id === userId;
        const isCustomerOwner = order.customer_id === userId;

        if (role === 'rider') {
            if (!isRiderOwner) {
                // Try to accept if it's still pending
                if (status === 'accepted' && order.status === 'pending') {
                    // ATOMIC UPDATE: Ensure it's still pending and no rider is assigned
                    const updateResult = await db.query(
                        'UPDATE orders SET status = $1, rider_id = $2, accepted_at = CURRENT_TIMESTAMP WHERE id = $3 AND status = \'pending\' AND rider_id IS NULL RETURNING id',
                        ['accepted', userId, order.id],
                    );
                    
                    if (updateResult.rows.length === 0) {
                        return res.status(409).json({ success: false, message: 'Too late! This order was just taken by another rider.' });
                    }

                    // Add to Rider's Pending Balance
                    if (parseFloat(order.rider_earning) > 0) {
                        await db.query(
                            'UPDATE wallets SET pending_balance = pending_balance + $1 WHERE user_id = $2',
                            [order.rider_earning, userId]
                        );
                    }
                } else {
                    return res.status(403).json({ success: false, message: 'This order is not assigned to you.' });
                }
            } else {
                // Rider owns the order, let them update to picked_up or delivered
                if (!['arrived', 'picked_up', 'delivered'].includes(status)) {
                    return res.status(400).json({ success: false, message: 'Invalid next status for this order.' });
                }
                
                const timestamps = { arrived: 'accepted_at', picked_up: 'picked_up_at', delivered: 'delivered_at' };
                const timestampCol = timestamps[status];
                
                await db.query(`UPDATE orders SET status = $1, ${timestampCol} = CURRENT_TIMESTAMP WHERE id = $2`, [status, order.id]);
            }
        } else if (role === 'customer') {
            if (!isCustomerOwner) {
                return res.status(403).json({ success: false, message: 'Access denied. You do not own this order.' });
            }
            // Customers can only cancel
            if (status !== 'cancelled') {
                return res.status(403).json({ success: false, message: 'Customers can only cancel orders through the /cancel endpoint.' });
            }
            // Redirect to cancel logic or allow it if it's pending
            if (order.status !== 'pending') {
                return res.status(400).json({ success: false, message: 'Orders can only be cancelled while pending.' });
            }
            await db.query('UPDATE orders SET status = \'cancelled\' WHERE id = $1', [order.id]);
        }

        // Create notification for customer about status update
        let title = 'Order Update';
        let msg = `Your order status has been updated to ${status.replace('_', ' ')}.`;

        if (status === 'accepted') {
            title = 'Rider Accepted!';
            msg = 'A rider has accepted your order and is heading to pickup.';
        } else if (status === 'picked_up') {
            title = 'Order Picked Up!';
            msg = 'Your package is on its way to the recipient.';
        } else if (status === 'delivered') {
            title = 'Delivered!';
            msg = 'Your package has been successfully delivered.';
        }

        await createNotification(
            order.customer_id,
            title,
            msg,
            'order',
            order.id
        );

        res.status(200).json({
            success: true,
            message: `Order status updated to ${status}.`,
            order: { ...order, status },
        });

    } catch (err) {
        console.error('Update order status error:', err);
        res.status(500).json({ success: false, message: 'Failed to update order status.' });
    }
};

/**
 * Cancel an order (Customer only, if status is pending)
 * PUT /api/orders/:id/cancel
 */
const cancelOrder = async (req, res) => {
    try {
        const { id } = req.params;

        // Check if order exists and belongs to user
        const orderResult = await db.query(
            'SELECT * FROM orders WHERE id = $1 AND customer_id = $2',
            [id, req.user.id]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Order not found.' });
        }

        const order = orderResult.rows[0];

        // Only allow cancellation if pending
        if (order.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: 'Only pending orders can be cancelled.'
            });
        }

        // Update status to cancelled
        const client = await db.connect();
        try {
            await client.query('BEGIN');

            await client.query(
                'UPDATE orders SET status = $1, cancelled_at = NOW(), updated_at = NOW() WHERE id = $2',
                ['cancelled', id]
            );

            // REFUND LOGIC
            if (order.payment_method === 'wallet') {
                const refundAmount = parseFloat(order.total_fare);
                
                // 1. Refund Customer
                await client.query(
                    'UPDATE wallets SET balance = balance + $1 WHERE user_id = $2',
                    [refundAmount, order.customer_id]
                );
                
                // 2. Reverse Vendor Pending (if applicable)
                if (order.vendor_id && parseFloat(order.item_price) > 0) {
                    await client.query(
                        'UPDATE wallets SET pending_balance = pending_balance - $1 WHERE user_id = $2',
                        [order.item_price, order.vendor_id]
                    );
                }

                // 3. Reverse Rider Pending (if applicable - though pending status means no rider)
                if (order.rider_id && parseFloat(order.rider_earning) > 0) {
                    await client.query(
                        'UPDATE wallets SET pending_balance = pending_balance - $1 WHERE user_id = $2',
                        [order.rider_earning, order.rider_id]
                    );
                }

                // 4. Record Refund Transaction
                await client.query(
                    `INSERT INTO wallet_transactions (wallet_id, type, amount, reference, description, status) 
                     SELECT id, 'credit', $1, $2, $3, 'completed' FROM wallets WHERE user_id = $4`,
                    [refundAmount, `RFD-${order.order_number}`, `Refund for cancelled order #${order.order_number}`, order.customer_id]
                );
            }

            await client.query('COMMIT');
        } catch (err) {
            await client.query('ROLLBACK');
            throw err;
        } finally {
            client.release();
        }

        // Create notification for customer
        await createNotification(
            req.user.id,
            'Order Cancelled!',
            `Your order #${order.order_number} has been successfully cancelled.`,
            'order',
            order.id
        );

        res.status(200).json({
            success: true,
            message: 'Order cancelled successfully.'
        });

    } catch (err) {
        console.error('Cancel order error:', err);
        res.status(500).json({ success: false, message: 'Failed to cancel order.' });
    }
};

/**
 * Confirm delivery and release funds from Escrow (Customer only)
 * PUT /api/orders/:id/confirm
 */
const confirmOrderDelivery = async (req, res) => {
    const { id } = req.params;
    const client = await db.connect();

    try {
        await client.query('BEGIN');

        // 1. Fetch the order with security checks
        const orderResult = await client.query(
            `SELECT * FROM orders 
             WHERE (id::text = $1 OR order_number = $1) AND customer_id = $2`,
            [id, req.user.id]
        );

        if (orderResult.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ success: false, message: 'Order not found or access denied.' });
        }

        const order = orderResult.rows[0];

        // 2. Validate order status for confirmation
        if (order.status !== 'delivered') {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: 'Order must be in "delivered" status to confirm.' });
        }

        if (order.customer_confirmed) {
            await client.query('ROLLBACK');
            return res.status(400).json({ success: false, message: 'Order has already been confirmed.' });
        }

        // 3. Update Order Status
        await client.query(
            `UPDATE orders 
             SET customer_confirmed = TRUE, payment_status = 'released', updated_at = NOW() 
             WHERE id = $1`,
            [order.id]
        );

        // 4. SETTLEMENT LOGIC (Automatic Wallet Splitting)
        
        // A. Payout to VENDOR (Item Price)
        if (order.vendor_id && parseFloat(order.item_price) > 0) {
            // Get or create vendor wallet
            let vendorWallet = await client.query('SELECT id, balance FROM wallets WHERE user_id = $1', [order.vendor_id]);
            let vwId, vBalanceBefore;
            if (vendorWallet.rows.length === 0) {
                const newW = await client.query('INSERT INTO wallets (user_id, balance) VALUES ($1, 0) RETURNING id, balance', [order.vendor_id]);
                vwId = newW.rows[0].id;
                vBalanceBefore = parseFloat(newW.rows[0].balance);
            } else {
                vwId = vendorWallet.rows[0].id;
                vBalanceBefore = parseFloat(vendorWallet.rows[0].balance);
            }

            const itemPrice = parseFloat(order.item_price);
            const vBalanceAfter = vBalanceBefore + itemPrice;

            // Credit vendor wallet (Move from Pending to Available)
            const vRef = `PYO-V-${order.order_number}`;
            await client.query(
                'UPDATE wallets SET balance = $1, pending_balance = pending_balance - $2, updated_at = NOW() WHERE id = $3',
                [vBalanceAfter, itemPrice, vwId]
            );
            await client.query(
                `INSERT INTO wallet_transactions (wallet_id, type, amount, balance_before, balance_after, reference, description, status) 
                 VALUES ($1, 'credit', $2, $3, $4, $5, $6, 'completed')`,
                [vwId, itemPrice, vBalanceBefore, vBalanceAfter, vRef, `Marketplace payout for order #${order.order_number}`]
            );
        }

        // B. Payout to RIDER (Rider Earning)
        if (order.rider_id && parseFloat(order.rider_earning) > 0) {
            // Get or create rider wallet
            let riderWallet = await client.query('SELECT id, balance FROM wallets WHERE user_id = $1', [order.rider_id]);
            let rwId, rBalanceBefore;
            if (riderWallet.rows.length === 0) {
                const newW = await client.query('INSERT INTO wallets (user_id, balance) VALUES ($1, 0) RETURNING id, balance', [order.rider_id]);
                rwId = newW.rows[0].id;
                rBalanceBefore = parseFloat(newW.rows[0].balance);
            } else {
                rwId = riderWallet.rows[0].id;
                rBalanceBefore = parseFloat(riderWallet.rows[0].balance);
            }

            const riderEarning = parseFloat(order.rider_earning);
            const rBalanceAfter = rBalanceBefore + riderEarning;

            // Credit rider wallet (Move from Pending to Available)
            const rRef = `PYO-R-${order.order_number}`;
            await client.query(
                'UPDATE wallets SET balance = $1, pending_balance = pending_balance - $2, updated_at = NOW() WHERE id = $3',
                [rBalanceAfter, riderEarning, rwId]
            );
            await client.query(
                `INSERT INTO wallet_transactions (wallet_id, type, amount, balance_before, balance_after, reference, description, status) 
                 VALUES ($1, 'credit', $2, $3, $4, $5, $6, 'completed')`,
                [rwId, riderEarning, rBalanceBefore, rBalanceAfter, rRef, `Delivery earning for order #${order.order_number}`]
            );
        }

        await client.query('COMMIT');

        // Create notification for Rider and Vendor
        if (order.rider_id) {
            await createNotification(order.rider_id, 'Payment Received!', `Funds for order #${order.order_number} have been released to your wallet.`, 'wallet', order.id);
        }
        if (order.vendor_id) {
            await createNotification(order.vendor_id, 'Payment Received!', `Item cost for order #${order.order_number} has been released to your wallet.`, 'wallet', order.id);
        }

        res.status(200).json({
            success: true,
            message: 'Order confirmed and payments released successfully.',
            order: { ...order, customer_confirmed: true, payment_status: 'released' }
        });

    } catch (err) {
        if (client) await client.query('ROLLBACK');
        console.error('Confirm order delivery error:', err);
        res.status(500).json({ success: false, message: 'Failed to confirm order.' });
    } finally {
        if (client) client.release();
    }
};

module.exports = {
    estimateFare,
    createOrder,
    getOrders,
    getOrderById,
    updateOrderStatus,
    cancelOrder,
    confirmOrderDelivery,
};
