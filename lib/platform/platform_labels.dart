import 'package:flutter/material.dart';

import '/flutter_flow/internationalization.dart';
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

/// Whether the active tenant has a platform module enabled.
bool platformModuleEnabled(PlatformModule module) =>
    PlatformConfigService.instance.isModuleEnabled(module);

/// Blocks order writes when the orders module is disabled for the tenant.
String? platformModuleOrderWriteBlockMessage() {
  if (platformModuleEnabled(PlatformModule.orders)) {
    return null;
  }
  return 'Order management is not enabled for this company. '
      'Contact your administrator or EmberSoulLabs support.';
}

/// Blocks WhatsApp import when the module is disabled.
String? platformModuleWhatsAppImportBlockMessage() {
  if (platformModuleEnabled(PlatformModule.whatsappImport)) {
    return null;
  }
  return 'WhatsApp order import is not available on your current plan.';
}
