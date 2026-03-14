// Give the service worker access to Firebase Messaging.
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyC__KRPXmSm79anWOxcqtteHRxkRO_Nacc',
  appId: '1:39874778249:web:65e1eb29ccfcd5a06def7f',
  messagingSenderId: '39874778249',
  projectId: 'zippa-logistics-28e7c',
  authDomain: 'zippa-logistics-28e7c.firebaseapp.com',
  storageBucket: 'zippa-logistics-28e7c.firebasestorage.app',
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
