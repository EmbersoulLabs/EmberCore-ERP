import 'dart:convert';

import 'package:http/http.dart' as http;

import '/backend/firebase/app_environment.dart';

class CustomerTrackingResult {
  const CustomerTrackingResult({
    required this.orderId,
    required this.status,
    required this.isPickup,
    required this.recipientNameMasked,
    required this.proofUrls,
    required this.companyName,
    required this.companyLogoUrl,
    this.deliveryDateIso,
    this.deliveryTimeSlot,
  });

  final String orderId;
  final String status;
  final bool isPickup;
  final String recipientNameMasked;
  final List<String> proofUrls;
  final String companyName;
  final String companyLogoUrl;
  final String? deliveryDateIso;
  final String? deliveryTimeSlot;

  factory CustomerTrackingResult.fromJson(Map<String, dynamic> json) {
    final proofs = <String>[];
    final rawProofs = json['proofUrls'];
    if (rawProofs is List) {
      for (final item in rawProofs) {
        final url = item?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          proofs.add(url);
        }
      }
    }
    return CustomerTrackingResult(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isPickup: json['isPickup'] == true,
      recipientNameMasked: json['recipientNameMasked']?.toString() ?? '',
      proofUrls: proofs,
      companyName: json['companyName']?.toString() ?? '',
      companyLogoUrl: json['companyLogoUrl']?.toString() ?? '',
      deliveryDateIso: json['deliveryDate']?.toString(),
      deliveryTimeSlot: json['deliveryTimeSlot']?.toString(),
    );
  }
}

class CustomerTrackingLookupException implements Exception {
  CustomerTrackingLookupException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}

String orderTrackingFunctionsProjectId() =>
    isStaging ? 'embercore-erp-staging' : 'embercore-erp';

Uri orderTrackingFunctionUri() {
  final projectId = orderTrackingFunctionsProjectId();
  return Uri.parse(
    'https://asia-southeast1-$projectId.cloudfunctions.net/getOrderTracking',
  );
}

Future<CustomerTrackingResult> fetchCustomerTracking({
  String? token,
  String? orderId,
  String? phoneLast4,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  final ownedClient = client == null;
  try {
    final body = <String, dynamic>{
      if (token != null && token.trim().isNotEmpty) 'token': token.trim(),
      if (orderId != null && orderId.trim().isNotEmpty)
        'orderId': orderId.trim(),
      if (phoneLast4 != null && phoneLast4.trim().isNotEmpty)
        'phoneLast4': phoneLast4.trim(),
    };
    if (body.isEmpty) {
      throw CustomerTrackingLookupException('invalid_request');
    }

    final response = await httpClient.post(
      orderTrackingFunctionUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);
    final map = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);

    if (response.statusCode == 404) {
      throw CustomerTrackingLookupException('not_found');
    }
    if (response.statusCode == 400) {
      throw CustomerTrackingLookupException(
        map['error']?.toString() ?? 'invalid_request',
        map['message']?.toString(),
      );
    }
    if (response.statusCode != 200 || map['ok'] != true) {
      throw CustomerTrackingLookupException(
        map['error']?.toString() ?? 'internal',
      );
    }

    final tracking = map['tracking'];
    if (tracking is! Map) {
      throw CustomerTrackingLookupException('invalid_response');
    }
    return CustomerTrackingResult.fromJson(
      Map<String, dynamic>.from(tracking),
    );
  } finally {
    if (ownedClient) {
      httpClient.close();
    }
  }
}
