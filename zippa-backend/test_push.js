const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require('./src/config/firebase-service-account.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const registrationToken = 'cW1ZbIirSVK7AH5tjyxs8B:APA91bEX7sbUnvJ9hsHeILvk3hfqEjMz30TJt9JQwosmRGQIZS5AESQZsc--QlN2nxCBQFPsck3V22LCgV_xR5sCY_yUsL64Y3gOf7hP_FyS5VkWz_prje8';

const message = {
    token: registrationToken,
    notification: {
        title: '🛰️ DIRECT TEST (V18)',
        body: 'If you see this, FCM is working perfectly on your phone!'
    },
    android: {
        priority: 'high',
        notification: {
            channelId: 'zippa_priority_alerts',
            priority: 'max',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
    },
    data: {
        title: '🛰️ DIRECT TEST (V18)',
        body: 'If you see this, FCM is working perfectly on your phone!',
        type: 'test'
    }
};

admin.messaging().send(message)
    .then((response) => {
        console.log('Successfully sent message:', response);
        process.exit(0);
    })
    .catch((error) => {
        console.error('Error sending message:', error);
        process.exit(1);
    });
