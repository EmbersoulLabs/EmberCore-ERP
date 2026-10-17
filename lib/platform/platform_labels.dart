import 'package:flutter/material.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/internationalization.dart';
import '/platform/plan_entitlements.dart';
import '/platform/platform_config_service.dart';
import '/platform/platform_module.dart';
import '/platform/tenant_platform_config.dart';

/// Resolves a tenant-customized field label for the active locale.
String platformFieldLabel(
  BuildContext context,
  PlatformFieldKey key,
) {
  final locale = FFLocalizations.of(context).languageCode;
  return platformFieldLabelForLocale(key, locale: locale);
}

/// Field label without [BuildContext] (PDF, exports, tests).
String platformFieldLabelForLocale(
  PlatformFieldKey key, {
  String locale = 'en',
}) =>
    PlatformConfigService.instance.fieldLabel(key, locale: locale);

/// Driver / field-staff role name for the active tenant.
String platformDriverRoleLabel(BuildContext context) {
  final locale = FFLocalizations.of(context).languageCode;
  return platformDriverRoleLabelForLocale(locale: locale);
}

String platformDriverRoleLabelForLocale({String locale = 'en'}) {
  final config = PlatformConfigService.instance.config;
  return locale.startsWith('zh')
      ? config.driverRoleLabelZh
      : config.driverRoleLabelEn;
}

/// Industry config, subscription plan, and Super Admin access.
/// Appointments stay off until the module is implemented.
bool platformModuleEnabled(PlatformModule module) {
  if (module == PlatformModule.appointments) {
    return false;
  }
  if (isSuperAdminRole(currentViewerRole())) {
    return true;
  }
  if (!PlatformConfigService.instance.isModuleEnabled(module)) {
    return false;
  }
  final company = TenantContext.instance.activeCompany;
  return planAllowsModule(
    subscriptionStatus: company?.subscriptionStatus,
    planTier: company?.planTier,
    module: module,
  );
}

String? _planDeniedMessage(PlatformModule module) {
  if (isSuperAdminRole(currentViewerRole())) {
    return null;
  }
  final company = TenantContext.instance.activeCompany;
  if (planAllowsModule(
    subscriptionStatus: company?.subscriptionStatus,
    planTier: company?.planTier,
    module: module,
  )) {
    return null;
  }
  return planUpgradeMessage(module);
}

/// Blocks order writes when the orders module is disabled for the tenant.
String? platformModuleOrderWriteBlockMessage() {
  if (platformModuleEnabled(PlatformModule.orders)) {
    return null;
  }
  return _planDeniedMessage(PlatformModule.orders) ??
      'Order management is not enabled for this company. '
          'Contact your administrator or EmberSoulLabs support.';
}

/// Blocks WhatsApp import when the module is disabled.
String? platformModuleWhatsAppImportBlockMessage() {
  if (platformModuleEnabled(PlatformModule.whatsappImport)) {
    return null;
  }
  return _planDeniedMessage(PlatformModule.whatsappImport) ??
      'WhatsApp order import is not enabled for this company.';
}
