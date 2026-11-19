import '/auth/role_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/shopify_reviews_record.dart';
import '/backend/tenant_query_helpers.dart';

const shopifyOrderSource = 'shopify';

abstract final class ShopifyReviewStatus {
  static const pendingReview = 'PENDING_REVIEW';
  static const approved = 'APPROVED';
  static const rejected = 'REJECTED';
  static const quarantined = 'QUARANTINED';
}

bool isShopifyReviewPending(ShopifyReviewsRecord review) =>
    review.reviewStatus == ShopifyReviewStatus.pendingReview ||
    review.reviewStatus == ShopifyReviewStatus.quarantined;

bool isShopifyReviewApproved(ShopifyReviewsRecord review) =>
    review.reviewStatus == ShopifyReviewStatus.approved;

bool isShopifyReviewSelectable(ShopifyReviewsRecord review) =>
    isShopifyReviewPending(review);

String shopifyReviewFinancialStatusKey(ShopifyReviewsRecord review) {
  final status = review.financialStatus.trim().toLowerCase();
  switch (status) {
    case 'paid':
    case 'voided':
    case 'pending':
    case 'partially_paid':
    case 'refunded':
    case 'partially_refunded':
    case 'authorized':
    case 'unpaid':
      return status;
    default:
      return status.isEmpty ? 'unknown' : status;
  }
}

bool shopifyReviewLooksPaid(ShopifyReviewsRecord review) =>
    shopifyReviewFinancialStatusKey(review) == 'paid';

bool shopifyReviewLooksVoided(ShopifyReviewsRecord review) {
  final key = shopifyReviewFinancialStatusKey(review);
  return key == 'voided' || key == 'refunded';
}

String shopifyReviewShopifyLabel(ShopifyReviewsRecord review) {
  if (review.shopifyOrderName.trim().isNotEmpty) {
    return review.shopifyOrderName.trim();
  }
  if (review.shopifyOrderId.trim().isNotEmpty) {
    return '#${review.shopifyOrderId.trim()}';
  }
  return 'Shopify';
}

String shopifyReviewCustomer(ShopifyReviewsRecord review) =>
    review.customerName.trim().isNotEmpty ? review.customerName.trim() : '-';

String shopifyReviewRecipient(ShopifyReviewsRecord review) {
  final recipient = review.recipientName.trim();
  if (recipient.isNotEmpty) {
    return recipient;
  }
  return shopifyReviewCustomer(review);
}

String shopifyReviewSenderPhone(ShopifyReviewsRecord review) {
  final sender = review.senderPhone.trim();
  if (sender.isNotEmpty) {
    return sender;
  }
  return review.phone.trim();
}

String shopifyReviewRecipientPhone(ShopifyReviewsRecord review) {
  final recipient = review.recipientPhone.trim();
  if (recipient.isNotEmpty) {
    return recipient;
  }
  return review.phone.trim();
}

String shopifyReviewDeliveryAddress(ShopifyReviewsRecord review) =>
    review.shippingAddress.trim();

String shopifyReviewBillingAddress(ShopifyReviewsRecord review) =>
    review.billingAddress.trim();

String shopifyReviewRemarks(ShopifyReviewsRecord review) =>
    review.remarks.trim();

List<String> shopifyReviewAddons(ShopifyReviewsRecord review) =>
    review.addons
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

List<Map<String, String>> shopifyReviewLineItemProperties(
  Map<String, dynamic> item,
) {
  final raw = item['properties'];
  if (raw is! List) {
    return const [];
  }
  final rows = <Map<String, String>>[];
  for (final entry in raw) {
    if (entry is! Map) {
      continue;
    }
    final name = '${entry['name'] ?? entry['key'] ?? ''}'.trim();
    final value = '${entry['value'] ?? ''}'.trim();
    if (name.isEmpty || value.isEmpty) {
      continue;
    }
    rows.add({'name': name, 'value': value});
  }
  return rows;
}

String _shopifyAttrKey(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[_.\-/]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isShopifyGiftMessageKey(String key) {
  if ((key.contains('gift') && key.contains('message')) ||
      (key.contains('card') && key.contains('message'))) {
    return true;
  }
  return key == 'message card' ||
      key == 'message on card' ||
      key == 'greeting card' ||
      key == 'greeting' ||
      key == 'card text' ||
      key == 'card content' ||
      key == 'gift wrap message' ||
      key == 'gift note' ||
      key == 'giftnote' ||
      key == 'message';
}

bool _isShopifyDedicatedLineProperty(String key) {
  if (key == 'tpo add by' || key.startsWith('tpo ')) {
    return true;
  }
  if (_isShopifyGiftMessageKey(key) ||
      key == 'from' ||
      key == 'from name' ||
      key == 'sender' ||
      key == 'to' ||
      key == 'to name' ||
      key == 'for' ||
      key == 'gift to') {
    return true;
  }
  if (key.contains('delivery') &&
      (key.contains('date') ||
          key.contains('time') ||
          key.contains('method') ||
          key.contains('service') ||
          key.contains('timing'))) {
    return true;
  }
  if (key == 'delivery' ||
      key == 'time slot' ||
      key == 'timeslot' ||
      key == 'pick up' ||
      key == 'pickup' ||
      key == 'self collect' ||
      key == 'collection' ||
      key == 'address' ||
      key == 'delivery address' ||
      key == 'recipient address' ||
      key == 'recipient name' ||
      key == 'receiver name' ||
      key == 'recipient' ||
      key == 'receiver' ||
      key == 'recipient hp no' ||
      key == 'recipient hp' ||
      key == 'recipient phone' ||
      key == 'receiver hp no' ||
      key == 'receiver phone' ||
      key == 'sender hp no' ||
      key == 'sender hp' ||
      key == 'sender phone' ||
      key == 'customer phone') {
    return true;
  }
  return false;
}

String shopifyReviewLineItemExtra(Map<String, dynamic> item) {
  final addons = <String>[];
  final extras = <String>[];
  final remarks = <String>[];
  for (final row in shopifyReviewLineItemProperties(item)) {
    final name = row['name']!;
    final value = row['value']!;
    final key = _shopifyAttrKey(name);
    if (key == 'addon' || key == 'add on' || key == 'add ons') {
      addons.add('Add-on: $value');
    } else if (key == 'remarks' || key == 'remark') {
      remarks.add(value);
    } else if (!_isShopifyDedicatedLineProperty(key)) {
      extras.add('$name: $value');
    }
  }
  return [...addons, ...extras, ...remarks].join('\n');
}

bool _isShopifyDeliveryFeeLine(Map<String, dynamic> item) =>
    shopifyReviewLineItemTitle(item).trim().toLowerCase() == 'delivery fee';

bool shopifyReviewShouldShowPerProductCards(
  Iterable<Map<String, dynamic>> items,
) =>
    items.where((item) => !_isShopifyDeliveryFeeLine(item)).length > 1;

String shopifyReviewLineItemCardMessage(Map<String, dynamic> item) {
  final stored = '${item['cardMessage'] ?? item['cardmessage'] ?? ''}'.trim();
  if (stored.isNotEmpty) {
    return stored;
  }
  var body = '';
  var to = '';
  var from = '';
  for (final row in shopifyReviewLineItemProperties(item)) {
    final key = _shopifyAttrKey(row['name']!);
    final value = row['value']!;
    if (body.isEmpty && _isShopifyGiftMessageKey(key)) {
      body = value;
    } else if (to.isEmpty &&
        (key == 'to' ||
            key == 'to name' ||
            key == 'for' ||
            key == 'gift to')) {
      to = value;
    } else if (from.isEmpty &&
        (key == 'from' || key == 'from name' || key == 'sender')) {
      from = value;
    }
  }
  final lines = <String>[];
  if (to.isNotEmpty) {
    lines.add('To: $to');
  }
  if (from.isNotEmpty) {
    lines.add('From: $from');
  }
  if (body.isNotEmpty) {
    if (lines.isNotEmpty) {
      lines.add('');
    }
    lines.add(body);
  }
  return lines.join('\n');
}

String shopifyReviewResolvedLineCardMessage({
  required Map<String, dynamic> item,
  required String orderCardMessage,
  required Iterable<Map<String, dynamic>> items,
}) {
  final own = shopifyReviewLineItemCardMessage(item);
  if (own.isNotEmpty) {
    return own;
  }
  if (shopifyReviewShouldShowPerProductCards(items) &&
      !_isShopifyDeliveryFeeLine(item)) {
    return orderCardMessage.trim();
  }
  return '';
}

String shopifyReviewDeliveryDateLabel(ShopifyReviewsRecord review) {
  final date = review.deliveryDate;
  if (date == null) {
    return '';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (date.month < 1 || date.month > 12) {
    return '';
  }
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String shopifyReviewScheduleLabel(ShopifyReviewsRecord review) {
  final date = shopifyReviewDeliveryDateLabel(review);
  final slot = review.deliveryTimeSlot.trim();
  if (date.isEmpty) {
    return slot;
  }
  if (slot.isEmpty) {
    return date;
  }
  return '$date · $slot';
}

String shopifyReviewProductSummary(ShopifyReviewsRecord review) {
  if (review.itemSummary.trim().isNotEmpty) {
    return review.itemSummary.trim();
  }
  if (review.lineItems.isEmpty) {
    return '-';
  }
  final parts = <String>[];
  for (final raw in review.lineItems.take(3)) {
    if (raw is! Map) {
      continue;
    }
    final qty = raw['qty'] ?? raw['quantity'] ?? 1;
    final name = raw['name'] ?? raw['title'] ?? 'Item';
    parts.add('${qty}x $name');
  }
  return parts.isEmpty ? '-' : parts.join(', ');
}

Map<String, dynamic>? shopifyReviewLineItemMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return null;
}

List<Map<String, dynamic>> shopifyReviewLineItemMaps(
  ShopifyReviewsRecord review,
) {
  return review.lineItems
      .map(shopifyReviewLineItemMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

bool _isTrustworthyReviewImageUrl(String? raw) {
  final url = raw?.trim() ?? '';
  if (url.isEmpty) {
    return false;
  }
  final lower = url.toLowerCase();
  if (lower.startsWith('data:') ||
      lower.startsWith('blob:') ||
      lower.startsWith('file:') ||
      lower.startsWith('javascript:')) {
    return false;
  }
  return lower.startsWith('https://') || lower.startsWith('gs://');
}

String? shopifyReviewLineItemImageUrl(Map<String, dynamic> item) {
  final candidates = [
    item['imageUrl'],
    item['image'],
  ];
  for (final candidate in candidates) {
    if (candidate is String && _isTrustworthyReviewImageUrl(candidate)) {
      return candidate.trim();
    }
  }
  return null;
}

String shopifyReviewLineItemTitle(Map<String, dynamic> item) {
  final title = '${item['title'] ?? item['name'] ?? 'Item'}'.trim();
  return title.isEmpty ? 'Item' : title;
}

String shopifyReviewLineItemVariant(Map<String, dynamic> item) {
  return '${item['variantTitle'] ?? item['variant_title'] ?? ''}'.trim();
}

int shopifyReviewLineItemQty(Map<String, dynamic> item) {
  final qty = item['qty'] ?? item['quantity'] ?? 1;
  if (qty is int) {
    return qty > 0 ? qty : 1;
  }
  return int.tryParse('$qty') ?? 1;
}

double shopifyReviewLineItemPrice(Map<String, dynamic> item) {
  final price = item['price'];
  if (price is num) {
    return price.toDouble();
  }
  return double.tryParse('$price') ?? 0;
}

List<String> shopifyReviewLineItemImageUrls(ShopifyReviewsRecord review) {
  return shopifyReviewLineItemMaps(review)
      .map(shopifyReviewLineItemImageUrl)
      .whereType<String>()
      .toList(growable: false);
}

Future<List<ShopifyReviewsRecord>> loadShopifyReviewsForQueue() async {
  return queryTenantShopifyReviewsRecordOnce(
    queryBuilder: (query) => query.orderBy('receivedAt', descending: true),
  );
}

List<ShopifyReviewsRecord> filterShopifyReviewsForQueue(
  Iterable<ShopifyReviewsRecord> reviews, {
  bool pendingOnly = true,
  String searchQuery = '',
}) {
  final needle = searchQuery.trim().toLowerCase();
  final filtered = reviews.where((review) {
    if (pendingOnly && !isShopifyReviewPending(review)) {
      return false;
    }
    if (needle.isEmpty) {
      return true;
    }
    final haystack = [
      shopifyReviewShopifyLabel(review),
      review.shopifyOrderId,
      review.officialOrderId,
      review.customerName,
      review.recipientName,
      review.phone,
      review.senderPhone,
      review.recipientPhone,
      review.shippingAddress,
      review.billingAddress,
      review.itemSummary,
      review.cardMessage,
      ...shopifyReviewLineItemMaps(review).map(shopifyReviewLineItemCardMessage),
      review.deliveryTimeSlot,
      review.notes,
      review.remarks,
      ...review.addons,
      review.financialStatus,
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }).toList(growable: false);

  filtered.sort((a, b) {
    final aTime = a.receivedAt ?? a.createdAtShopify ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.receivedAt ?? b.createdAtShopify ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return filtered;
}

bool canApproveShopifyReviews(UserRole? role) => canCreateOrders(role);

bool canDeleteShopifyReviews(UserRole? role) => canCreateOrders(role);
