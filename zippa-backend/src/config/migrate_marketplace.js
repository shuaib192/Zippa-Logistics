const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

async function migrate() {
    const pool = new Pool({
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'zippa_admin',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'zippa_logistics',
    });

    try {
        console.log('🚀 Running marketplace migrations...');
        
        await pool.query(`
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='customer_notes') THEN
                    ALTER TABLE orders ADD COLUMN customer_notes TEXT;
                END IF;
                
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='is_marketplace') THEN
                    ALTER TABLE orders ADD COLUMN is_marketplace BOOLEAN DEFAULT FALSE;
                END IF;
            END $$;
        `);

        console.log('✅ Migration successful!');
    } catch (err) {
        console.error('❌ Migration failed:', err.message);
    } finally {
        await pool.end();
    }
}

migrate();
