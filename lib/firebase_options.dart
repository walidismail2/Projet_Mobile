// File generated for PetCare — remplace via `flutterfire configure`
// ou colle les valeurs depuis la console Firebase.
//
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions non configuré pour cette plateforme.',
        );
    }
  }

  // TODO: remplace par tes vraies valeurs (Firebase Console → Paramètres du projet)

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD15n-Y5zhyu9kwf7Od9sr2S8jeAgAog1k',
    appId: '1:877636301598:android:2f19e1eb11d42de82a4f0f',
    messagingSenderId: '877636301598',
    projectId: 'pet-care-6b741',
    storageBucket: 'pet-care-6b741.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE:ios:REPLACE',
    messagingSenderId: 'REPLACE',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.example.flutterExample',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE:web:REPLACE',
    messagingSenderId: 'REPLACE',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
  );

  static bool get isConfigured =>
      android.apiKey != 'REPLACE_ME' && android.projectId != 'REPLACE_ME';
}
