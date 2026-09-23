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
    apiKey: 'AIzaSyADLfX1m27ygC2RqSsIGNgauPru5Fe6ubc',
    appId: '1:712579823358:web:852b0448bc5ed70d9bd7af',
    messagingSenderId: '712579823358',
    projectId: 'gerepag-9e692',
    authDomain: 'gerepag-9e692.firebaseapp.com',
    databaseURL: 'https://gerepag-9e692-default-rtdb.firebaseio.com',
    storageBucket: 'gerepag-9e692.firebasestorage.app',
    measurementId: 'G-NB49NTY9GF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLrc1UE2ed8ImwbeOVWtdXIDj_t96DQDY',
    appId: '1:712579823358:android:d5b614576ee632f89bd7af',
    messagingSenderId: '712579823358',
    projectId: 'gerepag-9e692',
    databaseURL: 'https://gerepag-9e692-default-rtdb.firebaseio.com',
    storageBucket: 'gerepag-9e692.firebasestorage.app',
  );

}