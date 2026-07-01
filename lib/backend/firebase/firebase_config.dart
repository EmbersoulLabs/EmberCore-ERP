import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '/backend/firebase/app_check_service.dart';
import '/backend/firebase/app_environment.dart';
import '/backend/firebase/firebase_secrets.dart';

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
      return stagingFirebaseWebOptions;
    case AppEnvironment.production:
      return productionFirebaseWebOptions;
  }
}
