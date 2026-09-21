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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCA1j7HcU38qxR_KTJZTtXyAkgHk-bgVuw',
    appId: '1:694627493774:web:af27a15fab6fa7c8e5e6df',
    messagingSenderId: '694627493774',
    projectId: 'financeiroapp-8b809',
    authDomain: 'financeiroapp-8b809.firebaseapp.com',
    storageBucket: 'financeiroapp-8b809.firebasestorage.app',
    measurementId: 'G-C2MPPKDLWJ',
    databaseURL: 'https://financeiroapp-8b809-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-ugnn7FSoHL6_2gDkz6MKnJJtVtZb91A',
    appId: '1:694627493774:android:7aa5c41dc837cc44e5e6df',
    messagingSenderId: '694627493774',
    projectId: 'financeiroapp-8b809',
    storageBucket: 'financeiroapp-8b809.firebasestorage.app',
    databaseURL: 'https://financeiroapp-8b809-default-rtdb.firebaseio.com',
  );
}
