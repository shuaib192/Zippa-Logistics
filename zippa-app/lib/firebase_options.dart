import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC__KRPXmSm79anWOxcqtteHRxkRO_Nacc',
    appId: '1:39874778249:web:65e1eb29ccfcd5a06def7f',
    messagingSenderId: '39874778249',
    projectId: 'zippa-logistics-28e7c',
    authDomain: 'zippa-logistics-28e7c.firebaseapp.com',
    storageBucket: 'zippa-logistics-28e7c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC__KRPXmSm79anWOxcqtteHRxkRO_Nacc',
    appId: '1:39874778249:android:c72eed6c68f4a3ab832258',
    messagingSenderId: '39874778249',
    projectId: 'zippa-logistics-28e7c',
    storageBucket: 'zippa-logistics-28e7c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC__KRPXmSm79anWOxcqtteHRxkRO_Nacc',
    appId: '1:39874778249:ios:65e1eb29ccfcd5a06def7f',
    messagingSenderId: '39874778249',
    projectId: 'zippa-logistics-28e7c',
    storageBucket: 'zippa-logistics-28e7c.firebasestorage.app',
    iosBundleId: 'com.zippa.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC__KRPXmSm79anWOxcqtteHRxkRO_Nacc',
    appId: '1:39874778249:ios:65e1eb29ccfcd5a06def7f',
    messagingSenderId: '39874778249',
    projectId: 'zippa-logistics-28e7c',
    storageBucket: 'zippa-logistics-28e7c.firebasestorage.app',
    iosBundleId: 'com.zippa.app',
  );
}
