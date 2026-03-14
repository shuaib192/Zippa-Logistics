// ============================================
// 🔔 NOTIFICATION SERVICE (notification.service.js)
// ============================================

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let isInitialized = false;

// Path to the local service account key file (if it exists)
const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json');

// In production, we prefer environment variables to avoid committing secrets
const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;

if (fs.existsSync(serviceAccountPath) || serviceAccountEnv) {
    try {
        let serviceAccount;
        if (serviceAccountEnv) {
            // Read from environment variable (String -> JSON)
            serviceAccount = JSON.parse(serviceAccountEnv);
        } else {
            // Read from local file
            serviceAccount = require(serviceAccountPath);
        }

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        isInitialized = true;
        console.log('✅ Firebase Admin SDK Initialized.');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin SDK:', error);
    }
} else {
    console.warn('⚠️ Firebase service account NOT FOUND (checked file and ENV).');
    console.warn('⚠️ Push notifications will be disabled.');
}

const NotificationService = {
    /**
     * Send a push notification to a specific user
     * @param {string} fcmToken - The target user's FCM token
     * @param {object} payload - { title, body, data }
     */
    sendToUser: async (fcmToken, { title, body, data = {} }) => {
        if (!isInitialized) {
            console.warn('Push notification skipped: Firebase not initialized.');
            return;
        }

        if (!fcmToken) {
            console.warn('Push notification skipped: No FCM token provided.');
            return;
        }

        const message = {
            notification: { title, body },
            data: data,
            token: fcmToken
        };

        try {
            const response = await admin.messaging().send(message);
            console.log('Successfully sent message:', response);
            return response;
        } catch (error) {
            console.error('Error sending push notification:', error);
            // If the token is invalid or expired, we should probably remove it from our DB
            if (error.code === 'messaging/registration-token-not-registered') {
                console.log('Token is no longer valid. Marking for cleanup...');
                // TODO: Implement token cleanup in DB if needed
            }
        }
    },

    /**
     * Send notification to multiple tokens
     */
    sendToMultiple: async (tokens, { title, body, data = {} }) => {
        if (!isInitialized || !tokens || tokens.length === 0) return;

        const message = {
            notification: { title, body },
            data: data,
            tokens: tokens.filter(t => t !== null)
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`${response.successCount} messages were sent successfully`);
            return response;
        } catch (error) {
            console.error('Error sending multicast notification:', error);
        }
    },

    /**
     * Send notification to a specific topic (e.g., 'riders')
     */
    sendToTopic: async (topic, { title, body, data = {} }) => {
        if (!isInitialized || !topic) return;

        const message = {
            notification: { title, body },
            data: data,
            topic: topic
        };

        try {
            const response = await admin.messaging().send(message);
            console.log(`Successfully sent message to topic ${topic}:`, response);
            return response;
        } catch (error) {
            console.error(`Error sending push to topic ${topic}:`, error);
        }
    }
};

module.exports = NotificationService;
