const pool = require('./src/config/database');

const setupSettingsTable = async () => {
    try {
        console.log('🚀 Starting settings table setup...');
        
        // Create table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS settings (
                id SERIAL PRIMARY KEY,
                key VARCHAR(255) UNIQUE NOT NULL,
                value VARCHAR(255) NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('✅ Settings table created or already exists.');

        // Insert or Update values (UPSERT)
        const defaults = [
            { key: 'base_fare', value: '1000' },
            { key: 'per_km_fare', value: '250' }
        ];

        for (const item of defaults) {
            await pool.query(`
                INSERT INTO settings (key, value)
                VALUES ($1, $2)
                ON CONFLICT (key) 
                DO UPDATE SET value = $2, updated_at = CURRENT_TIMESTAMP
            `, [item.key, item.value]);
        }
        
        console.log('✅ Settings synchronized with required values (1000 base, 250 per km).');
        process.exit(0);
    } catch (error) {
        console.error('❌ Setup failed:', error);
        process.exit(1);
    }
};

setupSettingsTable();
