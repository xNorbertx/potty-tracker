import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured yet');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJWtvN0pngLhmTL9_pkU7QqJLN4yRZW7A',
    appId: '1:39283042015:web:a4f6ca98f8e7213ad56b6a',
    messagingSenderId: '39283042015',
    projectId: 'baby-poop-tracker',
    authDomain: 'baby-poop-tracker.firebaseapp.com',
    storageBucket: 'baby-poop-tracker.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlt8uFKQ4PayunvS72N-jn0tCdDKMTSNs',
    appId: '1:39283042015:android:b8e76f2be649c643d56b6a',
    messagingSenderId: '39283042015',
    projectId: 'baby-poop-tracker',
    storageBucket: 'baby-poop-tracker.firebasestorage.app',
  );
}
