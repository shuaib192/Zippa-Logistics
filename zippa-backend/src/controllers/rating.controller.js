const db = require('../config/database');

/**
 * Submit a rating for a completed order
 * POST /api/ratings
 */
const submitRating = async (req, res) => {
    const { orderId, rating, comment } = req.body;

    if (!orderId || !rating) {
        return res.status(400).json({ success: false, message: 'Order ID and rating are required.' });
    }

    try {
        // 1. Get order details to get rider_id
        const orderRes = await db.query(
            'SELECT customer_id, rider_id, status FROM orders WHERE id = $1',
            [orderId]
        );

        if (orderRes.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Order not found.' });
        }

        const order = orderRes.rows[0];

        // 2. Validate user owns order and it's delivered
        if (order.customer_id !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Unauthorized.' });
        }

        if (order.status !== 'delivered') {
            return res.status(400).json({ success: false, message: 'You can only rate delivered orders.' });
        }

        // 3. Check if already rated
        const existing = await db.query(
            'SELECT id FROM ratings WHERE order_id = $1',
            [orderId]
        );

        if (existing.rows.length > 0) {
            return res.status(400).json({ success: false, message: 'You have already rated this order.' });
        }

        // 4. Insert rating
        await db.query(
            `INSERT INTO ratings (order_id, customer_id, rider_id, rating, comment) 
             VALUES ($1, $2, $3, $4, $5)`,
            [orderId, req.user.id, order.rider_id, rating, comment]
        );

        res.status(201).json({ success: true, message: 'Thank you for your feedback!' });

    } catch (err) {
        console.error('Submit rating error:', err);
        res.status(500).json({ success: false, message: 'Failed to submit rating.' });
    }
};

module.exports = { submitRating };
