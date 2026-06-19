import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/platform/platform_module.dart';
import '/platform/tenant_platform_config.dart';

/// Active tenant's industry modules, labels, and order settings from Firestore.
class PlatformConfigService extends ChangeNotifier {
  PlatformConfigService._();

  static final PlatformConfigService instance = PlatformConfigService._();

  static const collectionName = 'tenant_platform_config';

  TenantPlatformConfig _config = TenantPlatformConfig.genericDefaults();
  StreamSubscription<DocumentSnapshot>? _subscription;

  TenantPlatformConfig get config => _config;

  bool isModuleEnabled(PlatformModule module) => _config.isModuleEnabled(module);

  String fieldLabel(
    PlatformFieldKey key, {
    String locale = 'en',
  }) =>
      _config.fieldLabel(key, locale: locale);

  String statusLabel(String statusKey, {String locale = 'en'}) =>
      _config.statusLabel(statusKey, locale: locale);

  void setConfig(TenantPlatformConfig config) {
    _config = config;
    notifyListeners();
  }

  void resetToGenericDefaults() {
    _config = TenantPlatformConfig.genericDefaults();
    notifyListeners();
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    resetToGenericDefaults();
  }

  DocumentReference? _activeDocRef() {
    final companyRef = TenantContext.instance.writeCompanyRef ??
        TenantContext.instance.activeCompanyRef;
    if (companyRef == null) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(canonicalCompanyId(companyRef.id));
  }

  Future<void> loadForActiveCompany() async {
    _subscription?.cancel();
    _subscription = null;

    final docRef = _activeDocRef();
    if (docRef == null) {
      resetToGenericDefaults();
      return;
    }

    try {
      final snapshot = await docRef.get();
      setConfig(
        TenantPlatformConfig.fromFirestore(
          snapshot.data() as Map<String, dynamic>?,
        ),
      );
    } catch (_) {
      resetToGenericDefaults();
      return;
    }

    _subscription = docRef.snapshots().listen(
      (snapshot) {
        setConfig(
          TenantPlatformConfig.fromFirestore(
            snapshot.data() as Map<String, dynamic>?,
          ),
        );
      },
      onError: (_) {},
    );
  }

  Future<void> saveForActiveCompany(TenantPlatformConfig config) async {
    final docRef = _activeDocRef();
    if (docRef == null) {
      throw StateError('No active company for platform config save');
    }
    await docRef.set(config.toFirestore(), SetOptions(merge: true));
    setConfig(config);
  }
}
