const db = require('../config/database');

/**
 * VENDOR CONTROLLER (vendor.controller.js)
 * Handles vendor discovery for the Marketplace.
 */

// 1. Get all active marketplace categories
const getAllCategories = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT * FROM vendor_categories WHERE is_active = true ORDER BY name ASC'
        );
        res.status(200).json({ success: true, categories: result.rows });
    } catch (err) {
        console.error('Error fetching categories:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch categories' });
    }
};

// 2. Search vendors by category or name
const searchVendors = async (req, res) => {
    const { category_id, query } = req.query;

    try {
        let sql = `
            SELECT 
                u.id, u.full_name, u.avatar_url,
                up.business_name, up.business_address, up.business_category_id, up.banner_url,
                vc.name as category_name
            FROM users u
            JOIN user_profiles up ON u.id = up.user_id
            LEFT JOIN vendor_categories vc ON up.business_category_id = vc.id
            WHERE u.role = 'vendor' AND u.is_active = true
        `;
        const params = [];

        if (category_id) {
            params.push(category_id);
            sql += ` AND up.business_category_id = $${params.length}`;
        }

        if (query) {
            params.push(`%${query}%`);
            sql += ` AND (up.business_name ILIKE $${params.length} OR u.full_name ILIKE $${params.length})`;
        }

        const result = await db.query(sql, params);
        res.status(200).json({ success: true, vendors: result.rows });
    } catch (err) {
        console.error('Error searching vendors:', err.message);
        res.status(500).json({ success: false, message: 'Search failed' });
    }
};

// 3. Get featured vendors for home screen
const getFeaturedVendors = async (req, res) => {
    try {
        // For now, just return a few active vendors
        const result = await db.query(`
            SELECT 
                u.id, u.full_name, u.avatar_url,
                up.business_name, up.business_address, up.banner_url, vc.name as category_name
            FROM users u
            JOIN user_profiles up ON u.id = up.user_id
            LEFT JOIN vendor_categories vc ON up.business_category_id = vc.id
            WHERE u.role = 'vendor' AND u.is_active = true
            LIMIT 5
        `);
        res.status(200).json({ success: true, vendors: result.rows });
    } catch (err) {
        console.error('Error fetching featured vendors:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch featured vendors' });
    }
};

// 4. Get a single vendor's full details and their products
const getVendorDetails = async (req, res) => {
    const { id } = req.params;

    try {
        // Get vendor profile
        const vendorResult = await db.query(`
            SELECT 
                u.id, u.full_name, u.email, u.phone, u.avatar_url,
                up.business_name, up.business_address, up.business_reg_number,
                up.latitude, up.longitude, up.banner_url,
                vc.name as category_name
            FROM users u
            JOIN user_profiles up ON u.id = up.user_id
            LEFT JOIN vendor_categories vc ON up.business_category_id = vc.id
            WHERE u.id = $1 AND u.role = 'vendor'
        `, [id]);

        if (vendorResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Vendor not found' });
        }

        // Get vendor products
        const productsResult = await db.query(
            'SELECT * FROM products WHERE vendor_id = $1 AND is_available = true ORDER BY name ASC',
            [id]
        );

        res.status(200).json({
            success: true,
            vendor: vendorResult.rows[0],
            products: productsResult.rows
        });
    } catch (err) {
        console.error('Error fetching vendor details:', err.message);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

// 5. Toggle favorite status for a vendor
const toggleFavorite = async (req, res) => {
    const { vendor_id } = req.body;
    const user_id = req.user.id;

    try {
        // Check if already favorite
        const existing = await db.query(
            'SELECT id FROM user_favorites WHERE user_id = $1 AND vendor_id = $2',
            [user_id, vendor_id]
        );

        if (existing.rows.length > 0) {
            // Remove
            await db.query(
                'DELETE FROM user_favorites WHERE user_id = $1 AND vendor_id = $2',
                [user_id, vendor_id]
            );
            return res.status(200).json({ success: true, is_favorite: false, message: 'Removed from favorites' });
        } else {
            // Add
            await db.query(
                'INSERT INTO user_favorites (user_id, vendor_id) VALUES ($1, $2)',
                [user_id, vendor_id]
            );
            return res.status(200).json({ success: true, is_favorite: true, message: 'Added to favorites' });
        }
    } catch (err) {
        console.error('Error toggling favorite:', err.message);
        res.status(500).json({ success: false, message: 'Failed to update favorites' });
    }
};

// 6. Get user's favorite vendors
const getFavorites = async (req, res) => {
    const user_id = req.user.id;

    try {
        const result = await db.query(`
            SELECT 
                u.id, u.full_name, u.avatar_url,
                up.business_name, up.business_address, up.banner_url,
                vc.name as category_name
            FROM user_favorites uf
            JOIN users u ON uf.vendor_id = u.id
            JOIN user_profiles up ON u.id = up.user_id
            LEFT JOIN vendor_categories vc ON up.business_category_id = vc.id
            WHERE uf.user_id = $1 AND u.is_active = true
            ORDER BY uf.created_at DESC
        `, [user_id]);
        
        res.status(200).json({ success: true, vendors: result.rows });
    } catch (err) {
        console.error('Error fetching favorites:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch favorites' });
    }
};

// 7. Global product search
const searchProducts = async (req, res) => {
    const { query } = req.query;

    if (!query) {
        return res.status(400).json({ success: false, message: 'Search query is required' });
    }

    try {
        const result = await db.query(`
            SELECT 
                p.*,
                up.business_name as vendor_name,
                up.banner_url as vendor_banner
            FROM products p
            JOIN user_profiles up ON p.vendor_id = up.user_id
            WHERE p.is_available = true 
            AND (p.name ILIKE $1 OR p.description ILIKE $1)
            LIMIT 20
        `, [`%${query}%`]);
        
        res.status(200).json({ success: true, products: result.rows });
    } catch (err) {
        console.error('Error searching products:', err.message);
        res.status(500).json({ success: false, message: 'Product search failed' });
    }
};

module.exports = {
    getAllCategories,
    searchVendors,
    getFeaturedVendors,
    getVendorDetails,
    toggleFavorite,
    getFavorites,
    searchProducts
};
