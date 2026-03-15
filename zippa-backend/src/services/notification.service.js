// ============================================
// 🔔 NOTIFICATION SERVICE (notification.service.js)
// ============================================

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let isInitialized = false;

const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json');
const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;

if (fs.existsSync(serviceAccountPath) || serviceAccountEnv) {
    try {
        let serviceAccount;
        if (serviceAccountEnv) {
            serviceAccount = JSON.parse(serviceAccountEnv);
        } else {
            serviceAccount = require(serviceAccountPath);
        }

        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount)
            });
        }
        isInitialized = true;
        console.log('✅ Firebase Admin SDK Initialized.');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin SDK:', error);
    }
}

const NotificationService = {
    /**
     * HYBRID OPTION: Notification + Data
     * This provides the best of both worlds:
     * 1. OS handles the background tray (High reliability)
     * 2. App handles the foreground popup
     */
    _prepareHybridMessage: (target, { title, body, data = {} }) => {
        const message = {
            // 🔔 Standard notification object for the Android/iOS OS Tray
            notification: {
                title: title,
                body: body
            },
            // 📦 Additional data for app-side logic
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                zippa_msg_type: 'hybrid_push'
            },
            android: {
                priority: 'high', // Use high priority for aggressive delivery
                notification: {
                    channelId: 'zippa_alerts', // Must match FCMService and Manifest
                    priority: 'max',           // Force heads-up (popup)
                    sound: 'default',
                    visibility: 'public',      // Show on lockscreen
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                }
            },
            apns: {
                payload: {
                    aps: {
                        alert: { title, body },
                        sound: 'default'
                    }
                }
            }
        };

        if (target.startsWith('projects/') || target.includes(':')) {
            message.token = target;
        } else {
            message.topic = target;
        }

        return message;
    },

    sendToUser: async (fcmToken, payload) => {
        if (!isInitialized || !fcmToken) return;
        const message = NotificationService._prepareHybridMessage(fcmToken, payload);
        try {
            const response = await admin.messaging().send(message);
            console.log('Successfully sent hybrid message:', response);
            return response;
        } catch (error) {
            console.error('Error sending hybrid notification:', error);
        }
    },

    sendToMultiple: async (tokens, payload) => {
        if (!isInitialized || !tokens || tokens.length === 0) return;
        const messages = tokens
            .filter(t => t !== null)
            .map(t => NotificationService._prepareHybridMessage(t, payload));
        try {
            const response = await admin.messaging().sendEach(messages);
            console.log(`${response.successCount} hybrid messages were sent successfully`);
            return response;
        } catch (error) {
            console.error('Error sending multicast hybrid notification:', error);
        }
    },

    sendToTopic: async (topic, payload) => {
        if (!isInitialized || !topic) return;
        const message = NotificationService._prepareHybridMessage(topic, payload);
        try {
            const response = await admin.messaging().send(message);
            console.log(`Successfully sent hybrid message to topic ${topic}:`, response);
            return response;
        } catch (error) {
            console.error(`Error sending hybrid push to topic ${topic}:`, error);
        }
    }
};

module.exports = NotificationService;
