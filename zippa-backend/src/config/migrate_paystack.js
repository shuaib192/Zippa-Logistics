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
        console.log('🚀 Running Paystack Virtual Account migrations...');
        
        await pool.query(`
            DO $$ 
            BEGIN 
                -- Add Paystack customer code to wallets
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='wallets' AND column_name='paystack_customer_code') THEN
                    ALTER TABLE wallets ADD COLUMN paystack_customer_code VARCHAR(100);
                END IF;
                
                -- Add Virtual Account details to wallets
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='wallets' AND column_name='virtual_account_number') THEN
                    ALTER TABLE wallets ADD COLUMN virtual_account_number VARCHAR(20);
                END IF;

                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='wallets' AND column_name='virtual_bank_name') THEN
                    ALTER TABLE wallets ADD COLUMN virtual_bank_name VARCHAR(100);
                END IF;

                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='wallets' AND column_name='virtual_account_name') THEN
                    ALTER TABLE wallets ADD COLUMN virtual_account_name VARCHAR(255);
                END IF;

                -- For Transfers/Payouts (Rider/Vendor bank details)
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='wallets' AND column_name='paystack_recipient_code') THEN
                    ALTER TABLE wallets ADD COLUMN paystack_recipient_code VARCHAR(100);
                END IF;
            END $$;
        `);

        console.log('✅ Paystack Migration successful!');
    } catch (err) {
        console.error('❌ Paystack Migration failed:', err.message);
    } finally {
        await pool.end();
    }
}

migrate();
