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
  return PlatformConfigService.instance.fieldLabel(key, locale: locale);
}

/// Whether the active tenant has a platform module enabled.
bool platformModuleEnabled(PlatformModule module) =>
    PlatformConfigService.instance.isModuleEnabled(module);
