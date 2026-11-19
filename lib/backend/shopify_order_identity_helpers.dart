import '/backend/schema/orders_record.dart';
import '/backend/schema/shopify_reviews_record.dart';
import '/backend/shopify_pending_orders_helpers.dart';
import '/backend/tenant_query_helpers.dart';

/// True only for reviews waiting for normal human approval.
bool isShopifyReviewAwaitingApproval(ShopifyReviewsRecord review) =>
    review.reviewStatus == ShopifyReviewStatus.pendingReview;

int countShopifyReviewsAwaitingApproval(
  Iterable<ShopifyReviewsRecord> reviews, {
  String? companyId,
}) {
  final scoped = companyId == null || companyId.trim().isEmpty
      ? reviews
      : reviews.where((review) {
          final reviewCompany =
              review.companyId.trim().isNotEmpty
                  ? review.companyId.trim()
                  : (review.companyRef?.id ?? '');
          return reviewCompany == companyId.trim();
        });
  return scoped.where(isShopifyReviewAwaitingApproval).length;
}

/// Hidden when zero. Reuses the notice-bell overflow convention.
String? shopifyReviewPendingBadgeLabel(int count) {
  if (count <= 0) {
    return null;
  }
  if (count > 99) {
    return '99+';
  }
  return '$count';
}

Stream<int> watchShopifyReviewPendingBadgeCount() {
  return queryTenantShopifyReviewsRecord(
    queryBuilder: (query) => query.orderBy('receivedAt', descending: true),
  ).map(countShopifyReviewsAwaitingApproval);
}

String normalizeOrderSearchTerm(String raw) => raw.trim().toLowerCase();

String normalizeShopifySearchToken(String raw) {
  var token = raw.trim().toLowerCase();
  while (token.startsWith('#')) {
    token = token.substring(1).trim();
  }
  return token;
}

bool _looksLikeInternalShopifyId(String value) {
  final digits = normalizeShopifySearchToken(value);
  return RegExp(r'^\d{10,}$').hasMatch(digits);
}

String? _humanReadableShopifyName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || _looksLikeInternalShopifyId(trimmed)) {
    return null;
  }
  if (trimmed.startsWith('#')) {
    final rest = trimmed.substring(1).trim();
    if (rest.isEmpty || _looksLikeInternalShopifyId(rest)) {
      return null;
    }
    return '#$rest';
  }
  return '#$trimmed';
}

/// Staff-facing Shopify reference such as `#1340`. Never uses ERP Order_Id,
/// Firestore id, or the long Shopify payload.id.
String? resolveShopifyDisplayOrderName(OrdersRecord order) {
  final fromName = _humanReadableShopifyName(order.shopifyOrderName);
  if (fromName != null) {
    return fromName;
  }
  final fromLegacy = _humanReadableShopifyName(order.externalOrderName);
  if (fromLegacy != null) {
    return fromLegacy;
  }
  if (order.shopifyOrderNumber > 0) {
    return '#${order.shopifyOrderNumber}';
  }
  return null;
}

bool isOfficialShopifyOrder(OrdersRecord order) =>
    order.source.trim().toLowerCase() == shopifyOrderSource ||
    order.shopifyOrderName.trim().isNotEmpty ||
    order.shopifyOrderId.trim().isNotEmpty ||
    order.shopifyReviewId.trim().isNotEmpty ||
    (order.externalOrderId.trim().isNotEmpty &&
        order.source.trim().toLowerCase() == shopifyOrderSource);

bool orderMatchesShopifySearch(OrdersRecord order, String searchText) {
  final query = normalizeOrderSearchTerm(searchText);
  if (query.isEmpty) {
    return false;
  }
  final shopifyQuery = normalizeShopifySearchToken(searchText);
  final display = resolveShopifyDisplayOrderName(order);
  if (display != null) {
    final displayLower = display.toLowerCase();
    if (displayLower.contains(query)) {
      return true;
    }
    if (shopifyQuery.isNotEmpty &&
        normalizeShopifySearchToken(display).contains(shopifyQuery)) {
      return true;
    }
  }
  if (order.shopifyOrderNumber > 0 &&
      shopifyQuery.isNotEmpty &&
      '${order.shopifyOrderNumber}'.contains(shopifyQuery)) {
    return true;
  }
  return false;
}
