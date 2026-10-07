import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBviLIipdDaSKPtPW1iRHCT6UChQCg9d88',
    appId: '1:568564833537:android:a09468f5fc1523d3004f00',
    messagingSenderId: '568564833537',
    projectId: 'prep-civic',
    storageBucket: 'prep-civic.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCscZIPGYFPjYl4Wwf9eGHUw_1q_QtpkSE',
    appId: '1:568564833537:ios:e33838268ef1dc92004f00',
    messagingSenderId: '568564833537',
    projectId: 'prep-civic',
    storageBucket: 'prep-civic.firebasestorage.app',
    iosClientId:
        '568564833537-29tm6s4ca1apjrrpku9chs6rhnfijub9.apps.googleusercontent.com',
    iosBundleId: 'com.torcdigital.prepcivique',
  );
}
