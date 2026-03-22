const db = require('../config/database');

/**
 * Raise a new dispute for an order
 * POST /api/disputes
 */
const createDispute = async (req, res) => {
    try {
        const { order_id, reason, description } = req.body;

        if (!order_id || !reason || !description) {
            return res.status(400).json({ success: false, message: 'All fields are required.' });
        }

        // Verify order exists and belongs to user
        const orderRes = await db.query(
            'SELECT id, order_number, status, customer_confirmed FROM orders WHERE id = $1 AND customer_id = $2',
            [order_id, req.user.id]
        );

        if (orderRes.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Order not found or access denied.' });
        }

        const order = orderRes.rows[0];

        // Ensure order is not already fully confirmed (though they can still dispute, it's harder)
        // Usually disputes are raised before confirming payment release

        const result = await db.query(
            `INSERT INTO disputes (order_id, user_id, reason, description) 
             VALUES ($1, $2, $3, $4) 
             RETURNING id, status`,
            [order_id, req.user.id, reason, description]
        );

        // Update order status if necessary? Or just leave it as it is
        // We might want to mark the order as 'disputed' in the orders table too
        await db.query('UPDATE orders SET status = $1 WHERE id = $2', ['disputed', order_id]);

        // Notify Admin (optional in real use, but good for this system)
        console.log(`[DISPUTE] New dispute raised for order #${order.order_number}`);

        res.status(201).json({
            success: true,
            message: 'Dispute raised successfully. Our team will review it.',
            dispute: result.rows[0]
        });

    } catch (err) {
        console.error('Create dispute error:', err);
        res.status(500).json({ success: false, message: 'Failed to raise dispute.' });
    }
};

/**
 * Get all disputes for current user
 * GET /api/disputes
 */
const getMyDisputes = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT d.*, o.order_number 
             FROM disputes d 
             JOIN orders o ON d.order_id = o.id 
             WHERE d.user_id = $1 
             ORDER BY d.created_at DESC`,
            [req.user.id]
        );

        res.status(200).json({
            success: true,
            disputes: result.rows
        });
    } catch (err) {
        console.error('Get disputes error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch disputes.' });
    }
};

/**
 * Get dispute details
 * GET /api/disputes/:id
 */
const getDisputeById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query(
            `SELECT d.*, o.order_number, o.status as order_status 
             FROM disputes d 
             JOIN orders o ON d.order_id = o.id 
             WHERE d.id = $1 AND (d.user_id = $2 OR $3 = 'admin')`,
            [id, req.user.id, req.user.role]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Dispute not found.' });
        }

        res.status(200).json({
            success: true,
            dispute: result.rows[0]
        });
    } catch (err) {
        console.error('Get dispute by id error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch dispute details.' });
    }
};

module.exports = {
    createDispute,
    getMyDisputes,
    getDisputeById
};
