require('dotenv').config();
const { Pool } = require('pg');
const NotificationService = require('../services/notification.service');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: { rejectUnauthorized: false }
});

async function testPush(email) {
  try {
    console.log(`🔍 Looking for user with email: ${email}...`);
    const result = await pool.query('SELECT name, fcm_token FROM users WHERE email = $1', [email]);
    
    if (result.rows.length === 0) {
      console.log('❌ User not found.');
      process.exit(1);
    }
    
    const user = result.rows[0];
    if (!user.fcm_token) {
      console.log(`❌ User ${user.name} does not have an FCM token.`);
      console.log('👉 Tip: Ensure the user logs into the app to register their device token.');
      process.exit(1);
    }

    console.log(`✅ Found FCM Token for ${user.name}. Sending test notification...`);
    
    await NotificationService.sendToUser(user.fcm_token, {
      title: 'Test Notification 🚀',
      body: `Hello ${user.name}! Your push notifications are working perfectly on Zippa Logistics.`,
      data: { type: 'test' }
    });
    
    console.log('🎉 Test finished.');
  } catch (error) {
    console.error('❌ Error testing push notification:', error);
  } finally {
    pool.end();
    process.exit(0);
  }
}

const args = process.argv.slice(2);
if (args.length === 0) {
  console.log('Usage: node src/scripts/test-push.js <user_email>');
  process.exit(1);
}

testPush(args[0]);
