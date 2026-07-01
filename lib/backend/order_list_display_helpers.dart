import 'package:flutter/material.dart';

import '/backend/partial_delivery_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/order_status_display.dart';
import '/flutter_flow/flutter_flow_util.dart' show dateTimeFormat;
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_status_colors.dart';

/// Desktop operations table for order list rows.
const double kOrderListOpsBreakpoint = 1200;

/// Column labels for the order list table.
List<String> orderListColumnLabels(BuildContext context) => [
      tr(context, 'order.col.orderId'),
      tr(context, 'order.col.customer'),
      tr(context, 'order.col.phone'),
      tr(context, 'order.col.pd'),
      tr(context, 'order.col.deliveryDate'),
      tr(context, 'order.col.timeSlot'),
      tr(context, 'order.col.status'),
      tr(context, 'order.col.paymentStatus'),
      tr(context, 'order.col.driver'),
      tr(context, 'order.col.total'),
      tr(context, 'order.col.action'),
    ];

String orderListOrderId(OrdersRecord order) =>
    order.orderId.isNotEmpty ? order.orderId : order.reference.id;

String orderListCustomer(OrdersRecord order) =>
    order.clientName.isNotEmpty ? order.clientName : '-';

/// Recipient name when stored separately; falls back to customer for legacy orders.
String orderListRecipient(OrdersRecord order) {
  final recipient = order.recipientName;
  if (recipient.trim().isNotEmpty) {
    return recipient.trim();
  }
  return order.clientName.isNotEmpty ? order.clientName : '-';
}

String orderListAddress(OrdersRecord order) =>
    order.address.isNotEmpty ? order.address : '-';

String orderListDeliveryDate(OrdersRecord order, {String? locale}) {
  final effective = orderListEffectiveDate(order);
  if (effective == null) {
    return '-';
  }
  final date = dateTimeFormat(
    'd/M/y',
    effective,
    locale: locale,
  );
  if (!isRetailOrderRecord(order) && order.deliveryTimeSlot.isNotEmpty) {
    return '$date ${order.deliveryTimeSlot}';
  }
  return date;
}

String orderListDeliveryDateOnly(OrdersRecord order, {String? locale}) {
  final date = order.deliveryDate ?? orderListEffectiveDate(order);
  if (date == null) {
    return '-';
  }
  return dateTimeFormat('d/M/y', date, locale: locale);
}

String orderListDeliveryTimeSlot(OrdersRecord order) =>
    order.deliveryTimeSlot.isNotEmpty ? order.deliveryTimeSlot : '-';

String orderListPickupDelivery(BuildContext context, OrdersRecord order) {
  final raw = order.pickupDelivery.isNotEmpty
      ? order.pickupDelivery
      : order.orderType;
  if (raw.isEmpty) {
    return '-';
  }
  final lower = raw.toLowerCase();
  if (lower.contains('pick')) {
    return tr(context, 'order.type.pickupLabel');
  }
  if (lower.contains('deliver')) {
    return tr(context, 'order.type.delivery');
  }
  if (lower.contains('retail')) {
    return tr(context, 'order.type.retail');
  }
  return raw;
}

String orderListStatusLabel(BuildContext context, OrdersRecord order) {
  if (order.status != null) {
    return orderStatusDisplayLabel(context, order.status!);
  }
  return order.orderstatus.isNotEmpty ? order.orderstatus : '-';
}

String orderListPhone(OrdersRecord order) {
  final phone = order.recipientPhoneNumber.trim().isNotEmpty
      ? order.recipientPhoneNumber.trim()
      : order.customerPhoneNumber.trim();
  return phone.isNotEmpty ? phone : '-';
}

String orderListPaymentStatus(BuildContext context, OrdersRecord order) {
  if (order.balanceDue > 0.009) {
    if (order.amountPaid > 0.009) {
      return tr(context, 'order.payment.partial');
    }
    return tr(context, 'order.payment.unpaid');
  }
  return tr(context, 'order.payment.paid');
}

/// Sync fallback when a [StreamBuilder] is not available (e.g. exports).
String orderListDriverLabel(OrdersRecord order) {
  if (isRetailOrderRecord(order)) {
    return '—';
  }
  if (!order.hasAssignedDriver()) {
    return '—';
  }
  final id = order.assignedDriver!.id;
  return id.length > 8 ? id.substring(0, 8) : id;
}

String orderListTotal(OrdersRecord order) =>
    EmberBrand.formatMoney(order.total);

/// One line per product: name, optional remark, qty.
String orderListProductSummary(List<OrderItemRecord> items) {
  if (items.isEmpty) {
    return '-';
  }
  return items.map(formatOrderListProductLine).join('\n');
}

String formatOrderListProductLine(OrderItemRecord item) {
  final name = item.name.isNotEmpty ? item.name : 'Item';
  final remark = item.remark.trim();
  final qty = item.qty > 0 ? item.qty : 1;
  final delivered = readDeliveredQty(item);
  final remaining = remainingDeliveryQty(item);
  final qtyLabel = delivered > 0 && remaining > 0
      ? 'Qty $qty ($delivered delivered)'
      : delivered > 0 && remaining <= 0
          ? 'Qty $qty (delivered)'
          : 'Qty $qty';
  if (remark.isEmpty) {
    return '$name · $qtyLabel';
  }
  return '$name · $remark · $qtyLabel';
}

String formatOrderListProductLineLocalized(
  BuildContext context,
  OrderItemRecord item,
) {
  final name =
      item.name.isNotEmpty ? item.name : tr(context, 'common.item');
  final remark = item.remark.trim();
  final qty = item.qty > 0 ? item.qty : 1;
  final delivered = readDeliveredQty(item);
  final remaining = remainingDeliveryQty(item);
  final String qtyLabel;
  if (delivered > 0 && remaining > 0) {
    qtyLabel = tr(
      context,
      'order.product.qtyDeliveredPartial',
      params: {'qty': '$qty', 'delivered': '$delivered'},
    );
  } else if (delivered > 0 && remaining <= 0) {
    qtyLabel = tr(
      context,
      'order.product.qtyAllDelivered',
      params: {'qty': '$qty'},
    );
  } else {
    qtyLabel = tr(context, 'order.product.qtyOnly', params: {'qty': '$qty'});
  }
  if (remark.isEmpty) {
    return '$name · $qtyLabel';
  }
  return '$name · $remark · $qtyLabel';
}

String orderListProductSummaryLocalized(
  BuildContext context,
  List<OrderItemRecord> items,
) {
  if (items.isEmpty) {
    return '-';
  }
  return items
      .map((item) => formatOrderListProductLineLocalized(context, item))
      .join('\n');
}

List<OrderItemRecord> orderListItemsForOrder(
  List<OrderItemRecord> allItems,
  OrdersRecord order,
) =>
    allItems
        .where((item) => item.orderRef?.id == order.reference.id)
        .toList();

Color orderListStatusColor(OrderStatus? status) =>
    emberOrderStatusColor(status);
