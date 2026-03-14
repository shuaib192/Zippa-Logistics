require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: { rejectUnauthorized: false }
});

async function migrate() {
  try {
    console.log('🚀 Starting settings migration...');
    const sql = fs.readFileSync(path.join(__dirname, 'migrate_settings.sql'), 'utf8');
    await pool.query(sql);
    console.log('✅ Settings table created and seeded.');
  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await pool.end();
  }
}

migrate();
