import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/firebase/app_environment.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

const orderTrackingTokensCollection = 'order_tracking_tokens';

/// Web hosts used for customer tracking short links.
String customerTrackingWebOrigin() {
  if (kIsWeb) {
    return Uri.base.origin;
  }
  return isStaging
      ? 'https://embercore-erp-staging.web.app'
      : 'https://embercore-erp.web.app';
}

String customerTrackingPagePath({String? token, String? orderId}) {
  final params = <String, String>{};
  if (token != null && token.isNotEmpty) {
    params['t'] = token;
  }
  if (orderId != null && orderId.isNotEmpty) {
    params['orderId'] = orderId;
  }
  final uri = Uri(
    path: '/track',
    queryParameters: params.isEmpty ? null : params,
  );
  return uri.toString();
}

String customerTrackingAbsoluteUrl({required String token}) {
  final origin = customerTrackingWebOrigin().replaceAll(RegExp(r'/$'), '');
  return '$origin${customerTrackingPagePath(token: token)}';
}

String maskRecipientName(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final first = trimmed.split(RegExp(r'\s+')).first;
  final keep = first.substring(0, first.length < 3 ? first.length : 3);
  return '$keep***';
}

String phoneLast4Digits(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) {
    return '';
  }
  return digits.substring(digits.length - 4);
}

bool phonesMatchLast4(String? orderPhone, String? inputLast4) {
  final expected = phoneLast4Digits(orderPhone);
  final actual = (inputLast4 ?? '').replaceAll(RegExp(r'\D'), '');
  if (expected.isEmpty || actual.length != 4) {
    return false;
  }
  return expected == actual;
}

bool isRetailOrderRecord(OrdersRecord order) {
  final raw = order.pickupDelivery.isNotEmpty
      ? order.pickupDelivery
      : order.orderType;
  return raw.toLowerCase().contains('retail');
}

bool isTrackableCustomerOrder(OrdersRecord order) => !isRetailOrderRecord(order);

bool shouldAutoSendTrackingLink(OrdersRecord order, OrderStatus status) {
  if (!isTrackableCustomerOrder(order)) {
    return false;
  }
  if (isPickupOrderRecord(order)) {
    return status == OrderStatus.ready_to_delivery;
  }
  return status == OrderStatus.out_of_delivery;
}

String _randomTrackingToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Ensures [order] has a tracking token document + field. Returns the token.
Future<String> ensureOrderTrackingToken(OrdersRecord order) async {
  final existing = order.trackingToken.trim();
  if (existing.isNotEmpty) {
    final tokenDoc = await FirebaseFirestore.instance
        .collection(orderTrackingTokensCollection)
        .doc(existing)
        .get();
    if (tokenDoc.exists) {
      return existing;
    }
  }

  final token = _randomTrackingToken();
  final batch = FirebaseFirestore.instance.batch();
  final tokenRef = FirebaseFirestore.instance
      .collection(orderTrackingTokensCollection)
      .doc(token);
  batch.set(tokenRef, {
    'order_ref': order.reference,
    'company_ref': order.companyRef,
    'created_at': getCurrentTimestamp,
  });
  batch.update(order.reference, {'tracking_token': token});
  await batch.commit();
  return token;
}

String buildOrderTrackingWhatsAppMessage({
  required OrdersRecord order,
  required String trackingUrl,
}) {
  final orderId = orderDisplayId(order);
  final buffer = StringBuffer();
  if (isPickupOrderRecord(order)) {
    buffer
      ..writeln('Your order is ready for pickup.')
      ..writeln('Order ID: $orderId')
      ..writeln()
      ..writeln('Track your order:')
      ..write(trackingUrl);
  } else {
    buffer
      ..writeln('Your order is out for delivery.')
      ..writeln('Order ID: $orderId')
      ..writeln()
      ..writeln('Track your order:')
      ..write(trackingUrl);
  }
  return buffer.toString().trim();
}

Future<bool> launchOrderTrackingWhatsApp({
  required BuildContext context,
  required OrdersRecord order,
}) async {
  if (!isTrackableCustomerOrder(order)) {
    return false;
  }
  final phone = normalizeWhatsAppPhoneNumber(orderRecipientPhone(order));
  if (phone == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'track.whatsapp.missingPhone'))),
      );
    }
    return false;
  }

  try {
    final token = await ensureOrderTrackingToken(order);
    final url = customerTrackingAbsoluteUrl(token: token);
    final message = buildOrderTrackingWhatsAppMessage(
      order: order,
      trackingUrl: url,
    );
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'track.whatsapp.openFailed'))),
      );
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'track.whatsapp.openFailed'))),
      );
    }
    return false;
  }
}

/// After a status change, open WhatsApp tracking message when rules match.
Future<void> maybeLaunchTrackingWhatsAppAfterStatusChange({
  required BuildContext context,
  required DocumentReference orderRef,
  required OrderStatus status,
}) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  if (!shouldAutoSendTrackingLink(order, status)) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  await launchOrderTrackingWhatsApp(context: context, order: order);
}
