import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '/backend/firebase/app_environment.dart';

const storefrontCatalogFunctionsRegion = 'asia-southeast1';

class StorefrontCatalogSyncResult {
  const StorefrontCatalogSyncResult({
    required this.website,
    required this.createdCount,
    required this.priceUpdateCount,
    required this.deactivatedCount,
    required this.storefrontProducts,
    required this.firestoreProducts,
  });

  final String website;
  final int createdCount;
  final int priceUpdateCount;
  final int deactivatedCount;
  final int storefrontProducts;
  final int firestoreProducts;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

StorefrontCatalogSyncResult parseStorefrontCatalogSyncResult(
  Map<String, dynamic> payload,
) {
  return StorefrontCatalogSyncResult(
    website: '${payload['website'] ?? ''}',
    createdCount: _asInt(payload['createdCount'] ?? payload['created']?.length),
    priceUpdateCount: _asInt(
      payload['priceUpdateCount'] ?? payload['priceUpdates']?.length,
    ),
    deactivatedCount: _asInt(
      payload['deactivatedCount'] ?? payload['deactivated']?.length,
    ),
    storefrontProducts: _asInt(payload['storefrontProducts']),
    firestoreProducts: _asInt(payload['firestoreProducts']),
  );
}

String storefrontCatalogSyncSummary(StorefrontCatalogSyncResult result) {
  return 'Catalog updated: ${result.createdCount} added, '
      '${result.priceUpdateCount} prices, '
      '${result.deactivatedCount} deactivated.';
}

Uri storefrontCatalogSyncFunctionUri({String? projectId}) {
  final project = projectId ?? firebaseProjectId;
  return Uri.parse(
    'https://$storefrontCatalogFunctionsRegion-$project.cloudfunctions.net/syncStorefrontCatalog',
  );
}

Future<StorefrontCatalogSyncResult> syncStorefrontCatalog({
  required String companyId,
  required String website,
  http.Client? client,
  Future<String?> Function()? idToken,
  String? projectId,
}) async {
  final token = idToken != null
      ? await idToken()
      : await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null || token.isEmpty) {
    throw StateError('Sign in required to update catalog.');
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .post(
          storefrontCatalogSyncFunctionUri(projectId: projectId),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {
              'companyId': companyId,
              'website': website,
            },
          }),
        )
        .timeout(const Duration(seconds: 120));
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['error'] != null) {
      final error = decoded['error'];
      final message = error is Map
          ? '${error['message'] ?? error['status'] ?? 'Catalog update failed'}'
          : '$error';
      throw StateError(message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Catalog update failed (${response.statusCode}).');
    }
    final result = decoded is Map ? decoded['result'] ?? decoded : decoded;
    if (result is! Map) {
      throw StateError('Unexpected catalog update response.');
    }
    return parseStorefrontCatalogSyncResult(Map<String, dynamic>.from(result));
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
