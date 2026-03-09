const db = require('../config/database');

/**
 * PRODUCT CONTROLLER (product.controller.js)
 * Handles vendor-side product management (Add, Update, Delete).
 */

// 1. Get all products for the logged-in vendor
const getMyProducts = async (req, res) => {
    try {
        const result = await db.query(
            'SELECT p.*, vc.name as category_name FROM products p LEFT JOIN vendor_categories vc ON p.category_id = vc.id WHERE p.vendor_id = $1 ORDER BY p.created_at DESC',
            [req.user.id]
        );
        res.status(200).json({ success: true, products: result.rows });
    } catch (err) {
        console.error('Error fetching vendor products:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch products' });
    }
};

// 2. Add a new product
const addProduct = async (req, res) => {
    const { category_id, name, description, price, image_url, stock_quantity } = req.body;
    const vendor_id = req.user.id;

    if (!name || !price) {
        return res.status(400).json({ success: false, message: 'Name and price are required' });
    }

    try {
        const result = await db.query(
            `INSERT INTO products (vendor_id, category_id, name, description, price, image_url, stock_quantity) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [vendor_id, category_id, name, description, price, image_url, stock_quantity || 0]
        );

        res.status(201).json({ 
            success: true, 
            message: 'Product added successfully', 
            product: result.rows[0] 
        });
    } catch (err) {
        console.error('Error adding product:', err.message);
        res.status(500).json({ success: false, message: 'Failed to add product' });
    }
};

// 3. Update an existing product
const updateProduct = async (req, res) => {
    const { id } = req.params;
    const { category_id, name, description, price, image_url, stock_quantity, is_available } = req.body;

    try {
        // Verify ownership
        const check = await db.query('SELECT 1 FROM products WHERE id = $1 AND vendor_id = $2', [id, req.user.id]);
        if (check.rows.length === 0) {
            return res.status(403).json({ success: false, message: 'Unauthorized or product not found' });
        }

        const result = await db.query(
            `UPDATE products SET 
                category_id = COALESCE($1, category_id),
                name = COALESCE($2, name),
                description = COALESCE($3, description),
                price = COALESCE($4, price),
                image_url = COALESCE($5, image_url),
                stock_quantity = COALESCE($6, stock_quantity),
                is_available = COALESCE($7, is_available),
                updated_at = CURRENT_TIMESTAMP
             WHERE id = $8 AND vendor_id = $9 RETURNING *`,
            [category_id, name, description, price, image_url, stock_quantity, is_available, id, req.user.id]
        );

        res.status(200).json({ 
            success: true, 
            message: 'Product updated successfully', 
            product: result.rows[0] 
        });
    } catch (err) {
        console.error('Error updating product:', err.message);
        res.status(500).json({ success: false, message: 'Failed to update product' });
    }
};

// 4. Delete a product
const deleteProduct = async (req, res) => {
    const { id } = req.params;

    try {
        const result = await db.query(
            'DELETE FROM products WHERE id = $1 AND vendor_id = $2 RETURNING id',
            [id, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(403).json({ success: false, message: 'Unauthorized or product not found' });
        }

        res.status(200).json({ success: true, message: 'Product deleted successfully' });
    } catch (err) {
        console.error('Error deleting product:', err.message);
        res.status(500).json({ success: false, message: 'Failed to delete product' });
    }
};

module.exports = {
    getMyProducts,
    addProduct,
    updateProduct,
    deleteProduct
};
