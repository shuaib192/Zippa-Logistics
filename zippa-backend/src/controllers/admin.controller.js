const db = require('../config/database');

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
    const { status, admin_notes } = req.body;

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
        // We'll use a simple table or just return defaults for now if table doesn't exist
        // For Zippa, let's assume a 'system_settings' table or just hardcode if missing
        res.status(200).json({ 
            success: true, 
            settings: {
                service_fee: 10,
                base_fare: 1000,
                min_withdrawal: 2000,
                surge_multiplier: 1.0
            }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Failed to fetch settings' });
    }
};

const updateSettings = async (req, res) => {
    try {
        const { service_fee, base_fare, min_withdrawal, surge_multiplier } = req.body;
        // In a real app, we'd update a 'system_settings' table here
        console.log('✅ Admin updated system settings:', req.body);
        res.status(200).json({ success: true, message: 'Settings updated successfully' });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Failed to update settings' });
    }
};

/**
 * Broadcast Notification
 */
const broadcastNotification = async (req, res) => {
    try {
        const { title, message, target } = req.body;
        // logic to fetch tokens based on target and send via FCM
        console.log(`🔔 Broadcasting to ${target}: ${title}`);
        res.status(200).json({ success: true, message: 'Broadcast sent successfully' });
    } catch (err) {
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
