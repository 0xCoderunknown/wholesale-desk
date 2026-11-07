// Firebase options configuration
// Replace these with your actual Firebase project credentials or pass via environment/CLI.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return web;
    }
  }

  // Configuration for Web.
  // When hosting on Firebase Hosting or using your own Firebase project,
  // fill in these values or configure via `flutterfire configure`.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:1234567890:web:abcdef123456'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '1234567890'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'wholesale-desk-demo'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'wholesale-desk-demo.firebaseapp.com'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'wholesale-desk-demo.appspot.com'),
  );
}

