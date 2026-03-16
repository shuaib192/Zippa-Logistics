// ============================================
// 🔔 SCRUBBED NOTIFICATION SERVICE (v16 — DATA-ONLY)
//
// STRATEGY: Send DATA-ONLY payloads (no "notification" key).
// This forces the app to handle display via flutter_local_notifications
// on ALL Android versions, giving us full control over popups.
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
        console.log('✅ Firebase Admin SDK Initialized (v16 Data-Only).');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error);
    }
}

const NotificationService = {
    /**
     * DATA-ONLY PAYLOAD BUILDER (v16)
     * 
     * By NOT including a "notification" key, Android will NOT
     * display its own notification. Instead, the onMessage /
     * onBackgroundMessage handler in the Flutter app fires,
     * and WE control the display via flutter_local_notifications.
     * 
     * This guarantees: popup, sound, vibration on ALL devices.
     */
    _prepareDataOnlyMessage: (target, { title, body, data = {} }) => {
        const message = {
            // NO "notification" key — this is the key difference!
            data: {
                title: title || 'Zippa Alert',
                body: body || '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                )
            },
            android: {
                priority: 'high',
            },
            apns: {
                headers: { 'apns-priority': '10' },
                payload: {
                    aps: {
                        alert: { title, body },
                        sound: 'default',
                        'content-available': 1
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
        const message = NotificationService._prepareDataOnlyMessage(fcmToken, payload);
        try {
            const result = await admin.messaging().send(message);
            console.log('📤 Data-only notification sent:', result);
            return result;
        } catch (error) {
            console.error('❌ Error sending data-only notification:', error);
        }
    },

    sendToMultiple: async (tokens, payload) => {
        if (!isInitialized || !tokens || tokens.length === 0) return;
        const messages = tokens
            .filter(t => t !== null)
            .map(t => NotificationService._prepareDataOnlyMessage(t, payload));
        try {
            return await admin.messaging().sendEach(messages);
        } catch (error) {
            console.error('❌ Error sending multicast data-only notification:', error);
        }
    },

    sendToTopic: async (topic, payload) => {
        if (!isInitialized || !topic) return;
        const message = NotificationService._prepareDataOnlyMessage(topic, payload);
        try {
            const result = await admin.messaging().send(message);
            console.log(`📤 Data-only topic push sent to ${topic}:`, result);
            return result;
        } catch (error) {
            console.error(`❌ Error sending data-only push to topic ${topic}:`, error);
        }
    }
};

module.exports = NotificationService;
