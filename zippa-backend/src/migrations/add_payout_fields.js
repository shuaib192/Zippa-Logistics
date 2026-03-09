const db = require('../config/database');

async function migrate() {
    console.log('--- Starting Migration: Add Payout Fields to User Profiles ---');
    try {
        await db.query(`
            ALTER TABLE user_profiles 
            ADD COLUMN IF NOT EXISTS payout_bank_name VARCHAR(100),
            ADD COLUMN IF NOT EXISTS payout_account_number VARCHAR(20),
            ADD COLUMN IF NOT EXISTS payout_account_name VARCHAR(255),
            ADD COLUMN IF NOT EXISTS payout_bank_code VARCHAR(10);
        `);
        console.log('✅ Columns added to user_profiles table successfully.');
        process.exit(0);
    } catch (err) {
        console.error('❌ Migration failed:', err.message);
        process.exit(1);
    }
}

migrate();
