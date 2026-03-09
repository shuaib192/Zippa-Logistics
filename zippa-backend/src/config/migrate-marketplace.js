const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    user: process.env.DB_USER || 'zippa_admin',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zippa_logistics',
});

async function migrate() {
    console.log('👷 Running marketplace migrations...');
    try {
        // 1. Add missing columns to user_profiles
        await pool.query(`
            ALTER TABLE user_profiles 
            ADD COLUMN IF NOT EXISTS business_category_id UUID REFERENCES vendor_categories(id) ON DELETE SET NULL,
            ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
            ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8),
            ADD COLUMN IF NOT EXISTS banner_url TEXT,
            ADD CONSTRAINT user_profiles_user_id_unique UNIQUE (user_id);
        `);
        console.log('✅ Added business_category_id, latitude, longitude, and banner_url to user_profiles');

        // 2. Add missing columns to orders
        await pool.query(`
            ALTER TABLE orders 
            ADD COLUMN IF NOT EXISTS item_price DECIMAL(12, 2) DEFAULT 0,
            ADD COLUMN IF NOT EXISTS customer_confirmed BOOLEAN DEFAULT FALSE;
        `);
        console.log('✅ Added item_price and customer_confirmed to orders');

        // 3. Add image_urls to products
        await pool.query(`
            ALTER TABLE products 
            ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]',
            ADD CONSTRAINT products_vendor_name_unique UNIQUE (vendor_id, name);
        `);
        console.log('✅ Added image_urls to products and unique constraint');

        // 3. Seed Vendor Categories
        const categories = [
            { name: 'Groceries', icon: 'shopping_basket', image: 'https://images.unsplash.com/photo-1542838132-92c533004945' },
            { name: 'Pharmacy', icon: 'local_pharmacy', image: 'https://images.unsplash.com/photo-1587854692152-cbe660dbbb88' },
            { name: 'Restaurants', icon: 'restaurant', image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4' },
            { name: 'Drinks', icon: 'local_drink', image: 'https://images.unsplash.com/photo-1527661591475-527312dd65f5' },
            { name: 'Fashion', icon: 'checkroom', image: 'https://images.unsplash.com/photo-1445205170230-053b83016050' },
            { name: 'Electronics', icon: 'devices', image: 'https://images.unsplash.com/photo-1498049794561-7780e7231661' }
        ];

        for (const cat of categories) {
            await pool.query(
                `INSERT INTO vendor_categories (name, icon_name, image_url) 
                 VALUES ($1, $2, $3) 
                 ON CONFLICT (name) DO UPDATE SET icon_name = $2, image_url = $3`,
                [cat.name, cat.icon, cat.image]
            );
        }
        console.log('✅ Seeded marketplace categories');

        console.log('\n🚀 Migration complete!');
    } catch (err) {
        console.error('❌ Migration failed:', err.message);
    } finally {
        await pool.end();
    }
}

migrate();
