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
    apiKey: 'AIzaSyDpia-QNNqNiCOC2Lg8Dq_qCcInO2839WY',
    appId: '1:785020596808:web:4503542b589da163e81e7d',
    messagingSenderId: '785020596808',
    projectId: 'quiz-master-4ba8f',
    authDomain: 'quiz-master-4ba8f.firebaseapp.com',
    storageBucket: 'quiz-master-4ba8f.firebasestorage.app',
    measurementId: 'G-0Q6V5PT1P8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHmI1sM3mbByWMYVSfptJMfpDlUIpaHuU',
    appId: '1:785020596808:android:5a2ad593211f1bb1e81e7d',
    messagingSenderId: '785020596808',
    projectId: 'quiz-master-4ba8f',
    storageBucket: 'quiz-master-4ba8f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAm7QoX6-0Gk5_QmuhkRFbQ3csyCGuxjMw',
    appId: '1:785020596808:ios:71367c81d15f6ce4e81e7d',
    messagingSenderId: '785020596808',
    projectId: 'quiz-master-4ba8f',
    storageBucket: 'quiz-master-4ba8f.firebasestorage.app',
    iosBundleId: 'com.example.quizMaster',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAm7QoX6-0Gk5_QmuhkRFbQ3csyCGuxjMw',
    appId: '1:785020596808:ios:71367c81d15f6ce4e81e7d',
    messagingSenderId: '785020596808',
    projectId: 'quiz-master-4ba8f',
    storageBucket: 'quiz-master-4ba8f.firebasestorage.app',
    iosBundleId: 'com.example.quizMaster',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDpia-QNNqNiCOC2Lg8Dq_qCcInO2839WY',
    appId: '1:785020596808:web:079198de807a39fde81e7d',
    messagingSenderId: '785020596808',
    projectId: 'quiz-master-4ba8f',
    authDomain: 'quiz-master-4ba8f.firebaseapp.com',
    storageBucket: 'quiz-master-4ba8f.firebasestorage.app',
    measurementId: 'G-C5DJ0BW8SV',
  );
}
