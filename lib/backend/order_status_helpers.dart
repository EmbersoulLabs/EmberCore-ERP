import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/dashboard_order_stats_helpers.dart';
import '/backend/inventory_service.dart';
import '/backend/schema/enums/enums.dart';

/// Legacy string stored in Firestore field `orderstatus` (used by order list filters).
String legacyOrderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'pending';
    case OrderStatus.processing:
      return 'processing';
    case OrderStatus.ready_to_delivery:
      return 'readyToShip';
    case OrderStatus.out_of_delivery:
      return 'outOfDelivery';
    case OrderStatus.completed:
      return 'completed';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

/// Keeps enum `status` and legacy `orderstatus` in sync on writes.
Map<String, dynamic> createOrderStatusUpdateData(OrderStatus status) => {
      'status': status.serialize(),
      'orderstatus': legacyOrderStatusLabel(status),
    };

/// Updates order status and refreshes dashboard counts (pending, completed, etc.).
Future<void> updateOrderStatus(
  DocumentReference orderRef,
  OrderStatus status, {
  Map<String, dynamic> extraFields = const {},
}) async {
  final patch = <String, dynamic>{
    ...createOrderStatusUpdateData(status),
    ...extraFields,
  };

  if (status == OrderStatus.completed) {
    patch['inventory_frozen'] = true;
  }

  await orderRef.update(patch);
  notifyDashboardStatsChanged();

  if (status == OrderStatus.completed) {
    await applyInventoryOnOrderCompleted(orderRef);
  } else if (status == OrderStatus.cancelled) {
    await applyInventoryOnOrderCancelled(orderRef);
  }
}
