// ============================================
// 🎓 DATABASE CONNECTION (database.js)
// 
// This file creates a "connection pool" to PostgreSQL.
// 
// WHAT IS A CONNECTION POOL?
// Think of it like a restaurant with limited tables.
// Instead of building a new table for each customer (slow!),
// you reuse existing tables. A "pool" keeps several
// database connections open and ready to use.
//
// WHY pg LIBRARY?
// 'pg' (node-postgres) is the most popular PostgreSQL
// driver for Node.js. It's fast, reliable, and well-maintained.
// ============================================

// Load environment variables from .env file
// dotenv reads the .env file and makes values available as process.env.XXX
require('dotenv').config();

// Import the Pool class from the 'pg' library
const { Pool } = require('pg');

// Create a new connection pool
// This automatically connects to PostgreSQL using the values from .env
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    user: process.env.DB_USER || 'zippa_admin',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zippa_logistics',

    // Pool settings
    max: 20,          // Maximum 20 connections at once
    idleTimeoutMillis: 30000,  // Close idle connections after 30 seconds
    connectionTimeoutMillis: 2000, // Error if can't connect in 2 seconds
});

// Listen for errors on idle connections
// This prevents the app from crashing if a connection drops
pool.on('error', (err) => {
    console.error('❌ Unexpected database error:', err);
    process.exit(-1); // Exit if database connection is lost
});

// Export the pool so other files can use it
// Usage in other files: const db = require('./config/database');
//                       const result = await db.query('SELECT * FROM users');
module.exports = pool;
