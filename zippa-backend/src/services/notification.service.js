// ============================================
// 🔔 NOTIFICATION SERVICE (notification.service.js)
// ============================================

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let isInitialized = false;

// Path to the local service account key file
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
     * NUCLEAR OPTION: Send a DATA-ONLY push notification
     * By omitting the "notification" object, we skip the Android OS tray
     * and force the app code to run and show the notification manually.
     */
    _prepareNuclearMessage: (target, { title, body, data = {} }) => {
        const baseMessage = {
            // ☢️ NUCLEAR: We DO NOT use the "notification" key.
            // This prevents the Android OS from intercepting and potentially hiding it.
            data: {
                ...data,
                title: title,
                body: body,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                message_type: 'nuclear_push'
            },
            android: {
                priority: 'high',
                ttl: 3600 * 1000 // 1 hour
            }
        };

        if (target.startsWith('projects/') || target.includes(':')) {
            baseMessage.token = target;
        } else {
            baseMessage.topic = target;
        }

        return baseMessage;
    },

    sendToUser: async (fcmToken, payload) => {
        if (!isInitialized || !fcmToken) return;
        const message = NotificationService._prepareNuclearMessage(fcmToken, payload);
        
        try {
            const response = await admin.messaging().send(message);
            console.log('Successfully sent nuclear message:', response);
            return response;
        } catch (error) {
            console.error('Error sending nuclear notification:', error);
        }
    },

    sendToMultiple: async (tokens, payload) => {
        if (!isInitialized || !tokens || tokens.length === 0) return;
        
        const messages = tokens
            .filter(t => t !== null)
            .map(t => NotificationService._prepareNuclearMessage(t, payload));

        try {
            // multicasts for individual messages
            const response = await admin.messaging().sendEach(messages);
            console.log(`${response.successCount} nuclear messages were sent successfully`);
            return response;
        } catch (error) {
            console.error('Error sending multicast nuclear notification:', error);
        }
    },

    sendToTopic: async (topic, payload) => {
        if (!isInitialized || !topic) return;
        const message = NotificationService._prepareNuclearMessage(topic, payload);

        try {
            const response = await admin.messaging().send(message);
            console.log(`Successfully sent nuclear message to topic ${topic}:`, response);
            return response;
        } catch (error) {
            console.error(`Error sending nuclear push to topic ${topic}:`, error);
        }
    }
};

module.exports = NotificationService;
