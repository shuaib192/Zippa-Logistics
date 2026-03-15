// ============================================
// 🔔 SCRUBBED NOTIFICATION SERVICE (v14)
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
        console.log('✅ Firebase Admin SDK Initialized (Fresh Baseline).');
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error);
    }
}

const NotificationService = {
    /**
     * FRESH HYBRID SENDER (v14)
     * Strategy: Guaranteed Landing + Maximum Visibility
     */
    _prepareScrubbedMessage: (target, { title, body, data = {} }) => {
        const message = {
            notification: {
                title: title,
                body: body
            },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'zippa_priority_alerts', // NEW ID: Force system reset
                    priority: 'max',
                    sound: 'default',
                    visibility: 'public',
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
        const message = NotificationService._prepareScrubbedMessage(fcmToken, payload);
        try {
            return await admin.messaging().send(message);
        } catch (error) {
            console.error('Error sending scrubbed notification:', error);
        }
    },

    sendToMultiple: async (tokens, payload) => {
        if (!isInitialized || !tokens || tokens.length === 0) return;
        const messages = tokens
            .filter(t => t !== null)
            .map(t => NotificationService._prepareScrubbedMessage(t, payload));
        try {
            return await admin.messaging().sendEach(messages);
        } catch (error) {
            console.error('Error sending multicast scrubbed notification:', error);
        }
    },

    sendToTopic: async (topic, payload) => {
        if (!isInitialized || !topic) return;
        const message = NotificationService._prepareScrubbedMessage(topic, payload);
        try {
            return await admin.messaging().send(message);
        } catch (error) {
            console.error(`Error sending scrubbed push back to topic ${topic}:`, error);
        }
    }
};

module.exports = NotificationService;
