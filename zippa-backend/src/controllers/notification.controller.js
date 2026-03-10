const db = require('../config/database');

/**
 * Get notifications for current user
 * GET /api/notifications
 */
const getNotifications = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
            [req.user.id]
        );
        res.status(200).json({ success: true, notifications: result.rows });
    } catch (err) {
        console.error('Get notifications error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch notifications.' });
    }
};

/**
 * Mark notification as read
 * PUT /api/notifications/:id/read
 */
const markAsRead = async (req, res) => {
    try {
        await db.query(
            'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
            [req.params.id, req.user.id]
        );
        res.status(200).json({ success: true, message: 'Notification marked as read.' });
    } catch (err) {
        console.error('Mark read error:', err);
        res.status(500).json({ success: false, message: 'Failed to update notification.' });
    }
};

/**
 * Create a notification (Internal helper)
 */
const createNotification = async (userId, title, body, type = 'system', relatedId = null) => {
    try {
        await db.query(
            `INSERT INTO notifications (user_id, title, body, type, data) 
             VALUES ($1, $2, $3, $4, $5)`,
            [userId, title, body, type, relatedId ? { related_id: relatedId } : null]
        );
        return true;
    } catch (err) {
        console.error('Internal create notification error:', err);
        return false;
    }
};

module.exports = {
    getNotifications,
    markAsRead,
    createNotification
};
