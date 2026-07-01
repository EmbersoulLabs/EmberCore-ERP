import 'package:firebase_core/firebase_core.dart';

/// Copy to `firebase_secrets.dart` (gitignored) and paste keys from Firebase Console.
const FirebaseOptions stagingFirebaseWebOptions = FirebaseOptions(
  apiKey: 'YOUR_STAGING_WEB_API_KEY',
  authDomain: 'embercore-erp-staging.firebaseapp.com',
  projectId: 'embercore-erp-staging',
  storageBucket: 'embercore-erp-staging.firebasestorage.app',
  messagingSenderId: '598171125582',
  appId: 'YOUR_STAGING_WEB_APP_ID',
);

const FirebaseOptions productionFirebaseWebOptions = FirebaseOptions(
  apiKey: 'YOUR_PRODUCTION_WEB_API_KEY',
  authDomain: 'embercore-erp.firebaseapp.com',
  projectId: 'embercore-erp',
  storageBucket: 'embercore-erp.firebasestorage.app',
  messagingSenderId: '1098308969895',
  appId: 'YOUR_PRODUCTION_WEB_APP_ID',
);
