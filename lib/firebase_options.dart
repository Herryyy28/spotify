// File generated manually for Firebase configuration
// Project: music-hub-d96f6
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
    apiKey: 'AIzaSyB4iq8mssB4VBTgT7sXSKgEfm5Y0BkMMlI',
    appId: '1:447441384618:web:f2c3dfba8b58015be04cd3',
    messagingSenderId: '447441384618',
    projectId: 'music-hub-d96f6',
    authDomain: 'music-hub-d96f6.firebaseapp.com',
    storageBucket: 'music-hub-d96f6.firebasestorage.app',
    measurementId: 'G-4V2V2R7DB8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_Wo1eJ9rEW-ywJQIEhrwezrPBSNF4rVc',
    appId: '1:447441384618:android:c3d7d2ce442f6a13e04cd3',
    messagingSenderId: '447441384618',
    projectId: 'music-hub-d96f6',
    storageBucket: 'music-hub-d96f6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'music-hub-d96f6',
    storageBucket: 'music-hub-d96f6.appspot.com',
    iosBundleId: 'com.example.spotify',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'music-hub-d96f6',
    storageBucket: 'music-hub-d96f6.appspot.com',
    iosBundleId: 'com.example.spotify',
  );
}
