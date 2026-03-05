// ============================================
// 🎓 DATABASE SETUP SCRIPT (db-setup.js)
//
// This script creates all the database tables.
// Run it with: npm run db:setup
//
// It reads the schema.sql file and executes it
// against your PostgreSQL database.
//
// IMPORTANT: This is safe to run multiple times
// because we use "CREATE TABLE IF NOT EXISTS" —
// it won't destroy existing data.
// ============================================

const { Pool } = require('pg');
const fs = require('fs');      // 'fs' = File System, built-in Node.js module
const path = require('path');  // 'path' = helps build file paths correctly

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

async function setupDatabase() {
    console.log('🚀 Starting database setup...\n');

    // First, try to create the database itself
    // We connect to the default 'postgres' database to do this
    const adminPool = new Pool({
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'zippa_admin',
        password: process.env.DB_PASSWORD || '',
        database: 'postgres', // Connect to default database first
    });

    try {
        // Check if our database exists
        const dbName = process.env.DB_NAME || 'zippa_logistics';
        const checkDb = await adminPool.query(
            'SELECT 1 FROM pg_database WHERE datname = $1',
            [dbName]
        );
        // $1 is a "parameterized query" — it safely inserts the value
        // This prevents SQL injection attacks (a common hack)

        if (checkDb.rows.length === 0) {
            // Database doesn't exist, create it
            await adminPool.query(`CREATE DATABASE ${dbName}`);
            console.log(`✅ Created database: ${dbName}`);
        } else {
            console.log(`ℹ️  Database "${dbName}" already exists`);
        }
    } catch (err) {
        // If we can't create the database, it might already exist
        // or we might not have permission — that's usually OK
        console.log(`⚠️  Note: ${err.message}`);
    } finally {
        await adminPool.end(); // Close the admin connection
    }

    // Now connect to our actual database and create tables
    const pool = new Pool({
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'zippa_admin',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'zippa_logistics',
    });

    try {
        // Read the schema.sql file
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf-8');
        // readFileSync = read the entire file as text
        // 'utf-8' = text encoding (standard for English + most languages)

        // Execute the schema SQL
        await pool.query(schema);

        console.log('\n✅ All tables created successfully!');
        console.log('\n📋 Tables created:');
        console.log('   1. users              — All user accounts');
        console.log('   2. user_profiles      — Extended user details');
        console.log('   3. orders             — Delivery orders');
        console.log('   4. wallets            — User wallets');
        console.log('   5. wallet_transactions — Money movements');
        console.log('   6. kyc_documents      — Identity documents');
        console.log('   7. ratings            — Delivery ratings');
        console.log('   8. notifications      — In-app notifications');
        console.log('   9. refresh_tokens     — Auth refresh tokens');
        console.log('   10. audit_logs        — Security audit trail');
        console.log('   11. chat_messages     — AI chatbot history');
        console.log('\n🎉 Database is ready!\n');

    } catch (err) {
        console.error('❌ Error setting up database:', err.message);
        process.exit(1);
    } finally {
        await pool.end(); // Always close the connection when done
    }
}

// Run the function
setupDatabase();
