// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyDW5ANF5-EcrtpelTsAI9PdWkhcWKTXjbI',
    appId: '1:157870938030:web:bb1a5bd8c6bbf760941a3f',
    messagingSenderId: '157870938030',
    projectId: 'pbts-sms',
    authDomain: 'pbts-sms.firebaseapp.com',
    storageBucket: 'pbts-sms.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsYuG6oRjOMIPGDijfrJMExSEd_3bW0T4',
    appId: '1:157870938030:android:57ea27cbc24a4067941a3f',
    messagingSenderId: '157870938030',
    projectId: 'pbts-sms',
    storageBucket: 'pbts-sms.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyASgt096g_OC-PsLz8tSIo_jjapbQ-sLsc',
    appId: '1:157870938030:ios:7f42ee03bf20e42d941a3f',
    messagingSenderId: '157870938030',
    projectId: 'pbts-sms',
    storageBucket: 'pbts-sms.firebasestorage.app',
    iosBundleId: 'com.example.schoolManagementSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyASgt096g_OC-PsLz8tSIo_jjapbQ-sLsc',
    appId: '1:157870938030:ios:7f42ee03bf20e42d941a3f',
    messagingSenderId: '157870938030',
    projectId: 'pbts-sms',
    storageBucket: 'pbts-sms.firebasestorage.app',
    iosBundleId: 'com.example.schoolManagementSystem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDW5ANF5-EcrtpelTsAI9PdWkhcWKTXjbI',
    appId: '1:157870938030:web:3511f0f8cc636ccd941a3f',
    messagingSenderId: '157870938030',
    projectId: 'pbts-sms',
    authDomain: 'pbts-sms.firebaseapp.com',
    storageBucket: 'pbts-sms.firebasestorage.app',
  );
}
