
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCOeLDsYjFSL_pXfqc6QU5U09ls_HVd__Y',
    appId: '1:894320309904:web:008438fe4bca0a5c214a15',
    messagingSenderId: '894320309904',
    projectId: 'employee-eval-backend',
    authDomain: 'employee-eval-backend.firebaseapp.com',
    storageBucket: 'employee-eval-backend.firebasestorage.app',
    measurementId: 'G-99M98QMQH2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGnqz-pu2cx4I7cABuXkze243mXigTrDI',
    appId: '1:894320309904:android:7d64b7b0e41bbd3f214a15',
    messagingSenderId: '894320309904',
    projectId: 'employee-eval-backend',
    storageBucket: 'employee-eval-backend.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD0ptC4D9CdZkHmXvBIGQsKyjfjxxnad7I',
    appId: '1:894320309904:ios:07c791793e8c2cf4214a15',
    messagingSenderId: '894320309904',
    projectId: 'employee-eval-backend',
    storageBucket: 'employee-eval-backend.firebasestorage.app',
    iosBundleId: 'com.example.frontend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD0ptC4D9CdZkHmXvBIGQsKyjfjxxnad7I',
    appId: '1:894320309904:ios:07c791793e8c2cf4214a15',
    messagingSenderId: '894320309904',
    projectId: 'employee-eval-backend',
    storageBucket: 'employee-eval-backend.firebasestorage.app',
    iosBundleId: 'com.example.frontend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCOeLDsYjFSL_pXfqc6QU5U09ls_HVd__Y',
    appId: '1:894320309904:web:3e52233ccb35a076214a15',
    messagingSenderId: '894320309904',
    projectId: 'employee-eval-backend',
    authDomain: 'employee-eval-backend.firebaseapp.com',
    storageBucket: 'employee-eval-backend.firebasestorage.app',
    measurementId: 'G-4J1VM7MWW8',
  );
}
