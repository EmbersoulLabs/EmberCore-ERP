import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '/backend/order_whatsapp_import_helpers.dart';
import '/platform/platform_config_service.dart';
import '/platform/tenant_platform_config.dart';

const _functionsRegion = 'asia-southeast1';

Future<WhatsAppParsedOrderDetails?> _parseOrderImportWithGemini(
  String text,
) async {
  final platform = PlatformConfigService.instance.config;
  final callable = FirebaseFunctions.instanceFor(region: _functionsRegion)
      .httpsCallable('parseOrderImport');
  final response = await callable.call<Map<String, dynamic>>({
    'text': text,
    'industryKey': industryPresetKey(platform.industryPreset),
    'orderIdPrefix': platform.orderIdPrefix,
  });
  final data = response.data;
  final parsed = data['parsed'];
  if (parsed is! Map) {
    return null;
  }
  return WhatsAppParsedOrderDetails.fromRemoteMap(
    Map<String, dynamic>.from(parsed),
  );
}

/// Regex parser with optional Gemini merge (falls back to regex-only on failure).
Future<WhatsAppParsedOrderDetails> parseOrderImportText(String text) async {
  final local = parseWhatsAppOrderText(text);
  try {
    final ai = await _parseOrderImportWithGemini(text);
    if (ai == null) {
      return local;
    }
    return mergeParsedOrderDetails(local, ai);
  } catch (error, stack) {
    debugPrint('parseOrderImport callable failed: $error\n$stack');
    return local;
  }
}

/// Same as [parseOrderImportText] but shows a short loading dialog while Gemini runs.
Future<WhatsAppParsedOrderDetails> parseOrderImportTextForUi(
  BuildContext context,
  String text,
) async {
  if (!context.mounted) {
    return parseWhatsAppOrderText(text);
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text('Reading order details…')),
        ],
      ),
    ),
  );

  try {
    return await parseOrderImportText(text);
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
