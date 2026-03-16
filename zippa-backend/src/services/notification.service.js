// ============================================
// 🔔 NOTIFICATION SERVICE (v17 — HYBRID + HIGH PRIORITY)
//
// STRATEGY: Use HYBRID payload (notification + data).
// The "notification" key ensures the OS always displays 
// the notification natively — even when app is killed.
// The "data" key lets the app process it when open.
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
        console.log('✅ Firebase Admin SDK Initialized (v17 Hybrid).');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error);
    }
}

const NotificationService = {
    /**
     * HYBRID PAYLOAD (v17)
     * 
     * "notification" key → OS displays natively (works even when app is killed)
     * "data" key → App can process it (for click actions, navigation, etc.)
     * 
     * Android channelId ensures it routes to our high-importance channel.
     */
    _prepareMessage: (target, { title, body, data = {} }) => {
        const message = {
            notification: {
                title: title || 'Zippa Alert',
                body: body || ''
            },
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
                notification: {
                    channelId: 'zippa_priority_alerts',
                    priority: 'max',
                    defaultSound: true,
                    visibility: 'public',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                }
            },
            apns: {
                headers: { 'apns-priority': '10' },
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
        const message = NotificationService._prepareMessage(fcmToken, payload);
        try {
            const result = await admin.messaging().send(message);
            console.log('📤 Hybrid notification sent:', result);
            return result;
        } catch (error) {
            console.error('❌ Error sending notification:', error);
        }
    },

    sendToMultiple: async (tokens, payload) => {
        if (!isInitialized || !tokens || tokens.length === 0) return;
        const messages = tokens
            .filter(t => t !== null)
            .map(t => NotificationService._prepareMessage(t, payload));
        try {
            return await admin.messaging().sendEach(messages);
        } catch (error) {
            console.error('❌ Error sending multicast notification:', error);
        }
    },

    sendToTopic: async (topic, payload) => {
        if (!isInitialized || !topic) return;
        const message = NotificationService._prepareMessage(topic, payload);
        try {
            const result = await admin.messaging().send(message);
            console.log(`📤 Topic push sent to ${topic}:`, result);
            return result;
        } catch (error) {
            console.error(`❌ Error sending push to topic ${topic}:`, error);
        }
    }
};

module.exports = NotificationService;
