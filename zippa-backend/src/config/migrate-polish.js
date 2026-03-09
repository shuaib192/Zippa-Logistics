const pool = require('./database');
require('dotenv').config();

async function migrate() {
  const client = await pool.connect();
  try {
    console.log('🚀 Starting Customer Polish Migration...');

    // 1. Create user_favorites table
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_favorites (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        vendor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, vendor_id)
      );
    `);
    console.log('✅ Created user_favorites table');

    // 2. Add customer_notes to orders
    await client.query(`
      ALTER TABLE orders 
      ADD COLUMN IF NOT EXISTS customer_notes TEXT;
    `);
    console.log('✅ Added customer_notes to orders table');

    console.log('✨ Migration completed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err);
  } finally {
    client.release();
    process.exit();
  }
}

migrate();
