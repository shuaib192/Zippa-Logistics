// ============================================
// 🔔 NOTIFICATION SERVICE (notification.service.js)
// ============================================

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let isInitialized = false;

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json');

if (fs.existsSync(serviceAccountPath)) {
    try {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        isInitialized = true;
        console.log('✅ Firebase Admin SDK Initialized.');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin SDK:', error);
    }
} else {
    console.warn('⚠️ Firebase service account file NOT FOUND at:', serviceAccountPath);
    console.warn('⚠️ Push notifications will be disabled until the file is provided.');
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
    }
};

module.exports = NotificationService;
