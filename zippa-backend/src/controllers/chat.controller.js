const db = require('../config/database');
const NotificationService = require('../services/notification.service');

/**
 * Chat Controller
 * Handles real-time messaging between Rider and Customer
 */
const ChatController = {
    /**
     * Send a message for a specific order
     */
    sendMessage: async (req, res) => {
        try {
            const { orderId, message } = req.body;
            const senderId = req.user.id;

            // 1. Verify order existence and participants
            const orderRes = await db.query(
                `SELECT o.customer_id, o.rider_id, c.full_name as customer_name, r.full_name as rider_name,
                        c.fcm_token as customer_token, r.fcm_token as rider_token
                 FROM orders o
                 JOIN users c ON o.customer_id = c.id
                 LEFT JOIN users r ON o.rider_id = r.id
                 WHERE o.id = $1`,
                [orderId]
            );

            if (orderRes.rows.length === 0) {
                return res.status(404).json({ success: false, message: 'Order not found.' });
            }

            const order = orderRes.rows[0];

            // 2. Ensure sender is part of the order
            if (senderId !== order.customer_id && senderId !== order.rider_id) {
                return res.status(403).json({ success: false, message: 'Unauthorized.' });
            }

            // 3. Save message to DB
            const msgRes = await db.query(
                `INSERT INTO order_chat_messages (order_id, sender_id, message)
                 VALUES ($1, $2, $3)
                 RETURNING *`,
                [orderId, senderId, message]
            );

            const savedMsg = msgRes.rows[0];

            // 4. Notify recipient via FCM
            const recipientToken = (senderId === order.customer_id) ? order.rider_token : order.customer_token;
            const senderName = (senderId === order.customer_id) ? order.customer_name : order.rider_name;

            if (recipientToken) {
                NotificationService.sendToUser(recipientToken, {
                    title: `New message from ${senderName}`,
                    body: message,
                    data: {
                        type: 'chat',
                        orderId: orderId,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                });
            }

            res.status(201).json({ success: true, message: savedMsg });
        } catch (err) {
            console.error('Send message error:', err);
            res.status(500).json({ success: false, message: 'Failed to send message.' });
        }
    },

    /**
     * Get chat history for an order
     */
    getMessages: async (req, res) => {
        try {
            const { orderId } = req.params;
            const userId = req.user.id;

            // 1. Verify user is participant
            const orderCheck = await db.query(
                'SELECT customer_id, rider_id FROM orders WHERE id = $1',
                [orderId]
            );

            if (orderCheck.rows.length === 0) {
                return res.status(404).json({ success: false, message: 'Order not found.' });
            }

            if (userId !== orderCheck.rows[0].customer_id && userId !== orderCheck.rows[0].rider_id) {
                return res.status(403).json({ success: false, message: 'Unauthorized.' });
            }

            // 2. Fetch messages
            const messages = await db.query(
                `SELECT m.*, u.full_name as sender_name
                 FROM order_chat_messages m
                 JOIN users u ON m.sender_id = u.id
                 WHERE m.order_id = $1
                 ORDER BY m.created_at ASC`,
                [orderId]
            );

            res.status(200).json({ success: true, messages: messages.rows });
        } catch (err) {
            console.error('Get messages error:', err);
            res.status(500).json({ success: false, message: 'Failed to load messages.' });
        }
    }
};

module.exports = ChatController;
