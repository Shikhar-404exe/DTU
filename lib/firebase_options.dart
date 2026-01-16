/// Firebase Configuration for SIH 2025 Project
library;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBA_NA-BHXPc8foHV5oiZNOnk8jBr9QJ-Y',
    appId: '1:810050677328:android:a1c6fd4da6c16d4760bf55',
    messagingSenderId: '810050677328',
    projectId: 'sih-2025-4e10d',
    storageBucket: 'sih-2025-4e10d.firebasestorage.app',
  );

  // iOS configuration - Run `flutterfire configure` to generate actual credentials
  // These are placeholder values that will work for development but should be updated for production
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBA_NA-BHXPc8foHV5oiZNOnk8jBr9QJ-Y',
    appId: '1:810050677328:ios:a1c6fd4da6c16d4760bf55',
    messagingSenderId: '810050677328',
    projectId: 'sih-2025-4e10d',
    storageBucket: 'sih-2025-4e10d.firebasestorage.app',
    iosBundleId: 'com.ai.app',
  );

  // Web configuration - uses same project credentials
  // For production, generate proper web app credentials in Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBA_NA-BHXPc8foHV5oiZNOnk8jBr9QJ-Y',
    appId: '1:810050677328:web:a1c6fd4da6c16d4760bf55',
    messagingSenderId: '810050677328',
    projectId: 'sih-2025-4e10d',
    authDomain: 'sih-2025-4e10d.firebaseapp.com',
    storageBucket: 'sih-2025-4e10d.firebasestorage.app',
  );

  // macOS configuration - Uses same credentials as iOS for development
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBA_NA-BHXPc8foHV5oiZNOnk8jBr9QJ-Y',
    appId: '1:810050677328:macos:a1c6fd4da6c16d4760bf55',
    messagingSenderId: '810050677328',
    projectId: 'sih-2025-4e10d',
    storageBucket: 'sih-2025-4e10d.firebasestorage.app',
    iosBundleId: 'com.ai.app',
  );

  // Windows configuration - Uses Android credentials for development
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBA_NA-BHXPc8foHV5oiZNOnk8jBr9QJ-Y',
    appId: '1:810050677328:windows:a1c6fd4da6c16d4760bf55',
    messagingSenderId: '810050677328',
    projectId: 'sih-2025-4e10d',
    storageBucket: 'sih-2025-4e10d.firebasestorage.app',
  );
}
