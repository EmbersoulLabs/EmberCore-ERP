import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '/backend/firebase/app_environment.dart';

const shopifyFunctionsRegion = 'asia-southeast1';

class ShopifyBulkApproveResult {
  const ShopifyBulkApproveResult({
    required this.approved,
    required this.alreadyApproved,
    required this.failed,
  });

  final List<ShopifyApproveItemResult> approved;
  final List<ShopifyApproveItemResult> alreadyApproved;
  final List<ShopifyApproveFailure> failed;

  bool get hasFailures => failed.isNotEmpty;
  bool get hasSuccesses => approved.isNotEmpty || alreadyApproved.isNotEmpty;
  int get approvedCount => approved.length;
  int get alreadyApprovedCount => alreadyApproved.length;
}

class ShopifyApproveItemResult {
  const ShopifyApproveItemResult({
    required this.reviewId,
    required this.shopifyOrderId,
    required this.officialOrderId,
  });

  final String reviewId;
  final String shopifyOrderId;
  final String officialOrderId;
}

class ShopifyApproveFailure {
  const ShopifyApproveFailure({
    required this.reviewId,
    required this.code,
    required this.error,
  });

  final String reviewId;
  final String code;
  final String error;
}

ShopifyApproveItemResult? _parseItem(dynamic raw) {
  if (raw is! Map) {
    return null;
  }
  final map = Map<String, dynamic>.from(raw);
  return ShopifyApproveItemResult(
    reviewId: '${map['reviewId'] ?? ''}',
    shopifyOrderId: '${map['shopifyOrderId'] ?? ''}',
    officialOrderId: '${map['officialOrderId'] ?? ''}',
  );
}

ShopifyApproveFailure? _parseFailure(dynamic raw) {
  if (raw is! Map) {
    return null;
  }
  final map = Map<String, dynamic>.from(raw);
  return ShopifyApproveFailure(
    reviewId: '${map['reviewId'] ?? ''}',
    code: '${map['code'] ?? 'internal'}',
    error: '${map['error'] ?? 'Approval failed'}',
  );
}

ShopifyBulkApproveResult parseShopifyBulkApproveResult(Map<String, dynamic> payload) {
  final approved = <ShopifyApproveItemResult>[];
  final alreadyApproved = <ShopifyApproveItemResult>[];
  final failed = <ShopifyApproveFailure>[];
  for (final item in payload['approved'] as List? ?? const []) {
    final parsed = _parseItem(item);
    if (parsed != null) {
      approved.add(parsed);
    }
  }
  for (final item in payload['alreadyApproved'] as List? ?? const []) {
    final parsed = _parseItem(item);
    if (parsed != null) {
      alreadyApproved.add(parsed);
    }
  }
  for (final item in payload['failed'] as List? ?? const []) {
    final parsed = _parseFailure(item);
    if (parsed != null) {
      failed.add(parsed);
    }
  }
  return ShopifyBulkApproveResult(
    approved: approved,
    alreadyApproved: alreadyApproved,
    failed: failed,
  );
}

class ShopifyBulkDeleteResult {
  const ShopifyBulkDeleteResult({
    required this.deleted,
    required this.failed,
  });

  final List<ShopifyApproveItemResult> deleted;
  final List<ShopifyApproveFailure> failed;

  bool get hasFailures => failed.isNotEmpty;
  bool get hasSuccesses => deleted.isNotEmpty;
  int get deletedCount => deleted.length;
}

ShopifyBulkDeleteResult parseShopifyBulkDeleteResult(Map<String, dynamic> payload) {
  final deleted = <ShopifyApproveItemResult>[];
  final failed = <ShopifyApproveFailure>[];
  for (final item in payload['deleted'] as List? ?? const []) {
    final parsed = _parseItem(item);
    if (parsed != null) {
      deleted.add(parsed);
    }
  }
  for (final item in payload['failed'] as List? ?? const []) {
    final parsed = _parseFailure(item);
    if (parsed != null) {
      failed.add(parsed);
    }
  }
  return ShopifyBulkDeleteResult(deleted: deleted, failed: failed);
}

Uri shopifyApproveFunctionUri({String? projectId}) {
  final project = projectId ?? firebaseProjectId;
  return Uri.parse(
    'https://$shopifyFunctionsRegion-$project.cloudfunctions.net/approveShopifyReviews',
  );
}

/// Calls the authenticated approval gate. Server derives tenant + approver.
Future<ShopifyBulkApproveResult> approveShopifyReviews({
  required List<String> reviewIds,
  http.Client? client,
  Future<String?> Function()? idToken,
  String? projectId,
}) async {
  final ids = reviewIds.where((id) => id.trim().isNotEmpty).toSet().toList();
  if (ids.isEmpty) {
    throw StateError('No Shopify reviews selected.');
  }

  final token = idToken != null
      ? await idToken()
      : await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null || token.isEmpty) {
    throw StateError('Sign in required to approve Shopify reviews.');
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.post(
      shopifyApproveFunctionUri(projectId: projectId),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': {'reviewIds': ids},
      }),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['error'] != null) {
      final error = decoded['error'];
      final message = error is Map
          ? '${error['message'] ?? error['status'] ?? 'Approval failed'}'
          : '$error';
      throw StateError(message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Approval failed (${response.statusCode}).');
    }
    final result = decoded is Map ? decoded['result'] ?? decoded : decoded;
    if (result is! Map) {
      throw StateError('Unexpected approval response.');
    }
    return parseShopifyBulkApproveResult(Map<String, dynamic>.from(result));
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}

Uri shopifyDeleteFunctionUri({String? projectId}) {
  final project = projectId ?? firebaseProjectId;
  return Uri.parse(
    'https://$shopifyFunctionsRegion-$project.cloudfunctions.net/deleteShopifyReviews',
  );
}

/// Calls the authenticated delete gate. Server derives tenant + actor.
Future<ShopifyBulkDeleteResult> deleteShopifyReviews({
  required List<String> reviewIds,
  http.Client? client,
  Future<String?> Function()? idToken,
  String? projectId,
}) async {
  final ids = reviewIds.where((id) => id.trim().isNotEmpty).toSet().toList();
  if (ids.isEmpty) {
    throw StateError('No Shopify reviews selected.');
  }

  final token = idToken != null
      ? await idToken()
      : await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null || token.isEmpty) {
    throw StateError('Sign in required to delete Shopify reviews.');
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.post(
      shopifyDeleteFunctionUri(projectId: projectId),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'data': {'reviewIds': ids},
      }),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['error'] != null) {
      final error = decoded['error'];
      final message = error is Map
          ? '${error['message'] ?? error['status'] ?? 'Delete failed'}'
          : '$error';
      throw StateError(message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Delete failed (${response.statusCode}).');
    }
    final result = decoded is Map ? decoded['result'] ?? decoded : decoded;
    if (result is! Map) {
      throw StateError('Unexpected delete response.');
    }
    return parseShopifyBulkDeleteResult(Map<String, dynamic>.from(result));
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
