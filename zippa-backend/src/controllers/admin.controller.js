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

        // Log to audit logs (if we have it, otherwise just proceed)
        await db.query(
            'INSERT INTO audit_logs (user_id, action, resource, resource_id, details) VALUES ($1, $2, $3, $4, $5)',
            [req.user.id, 'kyc_update', 'users', id, JSON.stringify({ status, admin_notes })]
        ).catch(e => console.log('Audit log failed, skipping...'));

        res.status(200).json({ success: true, message: `KYC status updated to ${status}` });
    } catch (err) {
        console.error('KYC update error:', err);
        res.status(500).json({ success: false, message: 'Failed to update KYC status.' });
    }
};

module.exports = {
    getDashboardStats,
    getAllUsers,
    updateKYCStatus
};
