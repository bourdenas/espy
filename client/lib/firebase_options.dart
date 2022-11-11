// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars
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
    // ignore: missing_enum_constant_in_switch
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBLUWanZTnaV3z5HXWtUZ8R4TKmBW9_dbM',
    appId: '1:478783154654:web:d2215a196a0a4dc920954f',
    messagingSenderId: '478783154654',
    projectId: 'espy-library',
    authDomain: 'espy-library.firebaseapp.com',
    storageBucket: 'espy-library.appspot.com',
    measurementId: 'G-8JGK05CCQW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDv2v4XhewVMrHoq12MFKmllmaXQVe9Y9g',
    appId: '1:478783154654:android:c8ddd354962fa57620954f',
    messagingSenderId: '478783154654',
    projectId: 'espy-library',
    storageBucket: 'espy-library.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9MTP3zLsU67y3IibCmDH-BOiGq2FSmc4',
    appId: '1:478783154654:ios:0699b01f48faa95820954f',
    messagingSenderId: '478783154654',
    projectId: 'espy-library',
    storageBucket: 'espy-library.appspot.com',
    androidClientId: '478783154654-0kf23uvh2ma5l90ip176hg0s02s745f3.apps.googleusercontent.com',
    iosClientId: '478783154654-smue6eutb9k4hqojqiibto94hq0qk6lq.apps.googleusercontent.com',
    iosBundleId: 'com.bourdenas.espy',
  );
}