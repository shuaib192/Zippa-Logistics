const db = require('../config/database');
const NotificationService = require('../services/notification.service');

/**
 * Get core dashboard stats (KPIs)
 * GET /api/admin/stats
 */
const getDashboardStats = async (req, res) => {
    try {
        // 1. Total Users by role
        const usersCount = await db.query(
            'SELECT role, COUNT(*) as count FROM users GROUP BY role'
        );
        
        // 2. Total Orders by status
        const ordersCount = await db.query(
            'SELECT status, COUNT(*) as count FROM orders GROUP BY status'
        );

        // 3. Financial Stats
        const financialStats = await db.query(
            `SELECT 
                COALESCE(SUM(zippa_commission), 0) as total_revenue,
                (SELECT COALESCE(SUM(balance), 0) FROM wallets) as active_balance,
                (SELECT COALESCE(SUM(pending_balance), 0) FROM wallets) as escrow_balance
             FROM orders 
             WHERE payment_status = 'released'`
        );

        // 4. Recent Activity
        const recentOrders = await db.query(
            `SELECT o.*, u.full_name as customer_name 
             FROM orders o 
             JOIN users u ON o.customer_id = u.id 
             ORDER BY o.created_at DESC LIMIT 10`
        );

        res.status(200).json({
            success: true,
            stats: {
                users: usersCount.rows,
                orders: ordersCount.rows,
                finance: financialStats.rows[0],
                recentActivity: recentOrders.rows
            }
        });
    } catch (err) {
        console.error('Admin stats error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch dashboard stats.' });
    }
};

/**
 * List all users with filtering
 * GET /api/admin/users
 */
const getAllUsers = async (req, res) => {
    const { role, kyc_status, search } = req.query;
    
    try {
        let query = `
            SELECT id, email, phone, full_name, role, kyc_status, is_active, created_at 
            FROM users 
            WHERE 1=1
        `;
        const params = [];

        if (role) {
            params.push(role);
            query += ` AND role = $${params.length}`;
        }
        if (kyc_status) {
            params.push(kyc_status);
            query += ` AND kyc_status = $${params.length}`;
        }
        if (search) {
            params.push(`%${search}%`);
            query += ` AND (full_name ILIKE $${params.length} OR email ILIKE $${params.length} OR phone ILIKE $${params.length})`;
        }

        query += ' ORDER BY created_at DESC';

        const result = await db.query(query, params);
        res.status(200).json({ success: true, users: result.rows });
    } catch (err) {
        console.error('Admin users error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch users.' });
    }
};

/**
 * Update KYC status
 * PUT /api/admin/users/:id/kyc
 */
const updateKYCStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    try {
        await db.query(
            'UPDATE users SET kyc_status = $1, updated_at = NOW() WHERE id = $2',
            [status, id]
        );

        res.status(200).json({ success: true, message: `KYC status updated to ${status}` });
    } catch (err) {
        console.error('KYC update error:', err);
        res.status(500).json({ success: false, message: 'Failed to update KYC status.' });
    }
};

/**
 * List all orders with filtering
 */
const getAllOrders = async (req, res) => {
    const { status, search } = req.query;
    try {
        let query = `
            SELECT o.*, u.full_name as customer_name, r.full_name as rider_name 
            FROM orders o 
            LEFT JOIN users u ON o.customer_id = u.id 
            LEFT JOIN users r ON o.rider_id = r.id 
            WHERE 1=1
        `;
        const params = [];

        if (status) {
            params.push(status);
            query += ` AND o.status = $${params.length}`;
        }
        if (search) {
            params.push(`%${search}%`);
            query += ` AND (o.order_number ILIKE $${params.length} OR u.full_name ILIKE $${params.length})`;
        }

        query += ' ORDER BY o.created_at DESC';
        const result = await db.query(query, params);
        res.status(200).json({ success: true, orders: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Failed to fetch orders.' });
    }
};

/**
 * Manage Vendor Categories
 */
const getCategories = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM vendor_categories ORDER BY name ASC');
        res.status(200).json({ success: true, categories: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Failed to fetch categories.' });
    }
};

/**
 * Withdrawal Requests
 */
const getWithdrawals = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT w.*, u.full_name, u.email 
             FROM withdrawals w 
             JOIN users u ON w.user_id = u.id 
             ORDER BY w.created_at DESC`
        );
        res.status(200).json({ success: true, withdrawals: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Failed to fetch withdrawals.' });
    }
};

/**
 * System Settings
 */
const getSettings = async (req, res) => {
    try {
        const result = await db.query('SELECT key, value FROM settings');
        const settings = {};
        result.rows.forEach(row => {
            settings[row.key] = row.value; // Store as string, parse as needed in app
        });

        // Ensure defaults exist if table is empty
        const finalSettings = {
            base_fare: settings.base_fare || '1000',
            per_km_fare: settings.per_km_fare || '250',
            service_fee: settings.service_fee || '10',
            min_withdrawal: settings.min_withdrawal || '2000',
            surge_multiplier: settings.surge_multiplier || '1.0'
        };

        res.status(200).json({ 
            success: true, 
            settings: finalSettings
        });
    } catch (err) {
        console.error('❌ Admin getSettings error:', err);
        res.status(500).json({ success: false, message: 'Failed to fetch settings' });
    }
};

const updateSettings = async (req, res) => {
    try {
        const settings = req.body; // Expecting { key: value, ... }
        
        for (const [key, value] of Object.entries(settings)) {
            await db.query(`
                INSERT INTO settings (key, value)
                VALUES ($1, $2)
                ON CONFLICT (key) 
                DO UPDATE SET value = $2, updated_at = CURRENT_TIMESTAMP
            `, [key, value.toString()]);
        }

        console.log('✅ Admin updated system settings:', settings);
        res.status(200).json({ success: true, message: 'Settings updated successfully' });
    } catch (err) {
        console.error('❌ Admin updateSettings error:', err);
        res.status(500).json({ success: false, message: 'Failed to update settings' });
    }
};

/**
 * Broadcast Notification
 */
const broadcastNotification = async (req, res) => {
    try {
        const { title, body, target } = req.body;
        
        console.log(`🔔 Broadcasting to ${target}: ${title}`);
        
        if (target === 'all') {
            // Send to topic 'all' if you subscribe everyone, or multicast to all tokens
            // For now, let's just send to the three main topics
            NotificationService.sendToTopic('customers', { title, body, data: { type: 'broadcast' } });
            NotificationService.sendToTopic('riders', { title, body, data: { type: 'broadcast' } });
            NotificationService.sendToTopic('vendors', { title, body, data: { type: 'broadcast' } });
        } else if (['customer', 'rider', 'vendor'].includes(target)) {
            // The targets perfectly match topic names if we pluralize them
            const topicName = target + 's'; 
            NotificationService.sendToTopic(topicName, { 
                title, 
                body, 
                data: { type: 'broadcast' } 
            });
        }
        
        res.status(200).json({ success: true, message: 'Broadcast initiated successfully' });
    } catch (err) {
        console.error('Broadcast error:', err);
        res.status(500).json({ success: false, message: 'Failed to send broadcast' });
    }
};

module.exports = {
    getDashboardStats,
    getAllUsers,
    updateKYCStatus,
    getAllOrders,
    getCategories,
    getWithdrawals,
    getSettings,
    updateSettings,
    broadcastNotification
};
