const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require('./src/config/firebase-service-account.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

// User's most recent token (V20)
const registrationToken = 'fpmqb7ikRh2dpiMnGVIB6g:APA91bFF7Ke7ou7GpkcqVNOVkr4Ct4vVwyQdjsY6V9xgXMtaREi5OJjwcv7Dz6fbKaVn18vtaA7DVLiQ9PHgZwkr7ydBVhOPZ_vdQLir5EIHXZHYtZjJlBI';

// DATA-ONLY Payload (Most reliable for custom Flutter layouts)
const message = {
    token: registrationToken,
    data: {
        title: '🛰️ DIRECT DATA-ONLY (V20)',
        body: 'End-to-end success! Total consistency achieved.',
        type: 'test'
    },
    android: {
        priority: 'high',
        // Still provide system hints if the OS tries to peek
        ttl: 3600 * 1000, 
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
