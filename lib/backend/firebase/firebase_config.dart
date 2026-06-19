import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '/backend/firebase/app_check_service.dart';
import '/backend/firebase/app_environment.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(options: _webOptionsFor(appEnvironment));
    await initAppCheck();
    try {
      await FirebaseFirestore.instance.enablePersistence();
    } catch (_) {
      // Multi-tab or unsupported browser — online-only fallback.
    }
    return;
  }

  await Firebase.initializeApp();
  await initAppCheck();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

FirebaseOptions _webOptionsFor(AppEnvironment env) {
  switch (env) {
    case AppEnvironment.staging:
      return const FirebaseOptions(
        apiKey: 'REDACTED_API_KEY',
        authDomain: 'tfg-vday-record-staging.firebaseapp.com',
        projectId: 'tfg-vday-record-staging',
        storageBucket: 'tfg-vday-record-staging.firebasestorage.app',
        messagingSenderId: '972558847351',
        appId: '1:972558847351:web:3d6ebb53318abb5f9a2572',
      );
    case AppEnvironment.production:
      return const FirebaseOptions(
        apiKey: 'REDACTED_API_KEY',
        authDomain: 'embercore-erp.firebaseapp.com',
        projectId: 'embercore-erp',
        storageBucket: 'embercore-erp.firebasestorage.app',
        messagingSenderId: '1098308969895',
        appId: '1:1098308969895:web:15747b5faa30917cff8282',
      );
  }
}
