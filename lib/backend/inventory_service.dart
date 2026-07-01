import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/create_order_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_util.dart';

enum InventoryMovementType {
  stockIn,
  stockOut,
  sale,
  saleReversal,
}

String inventoryMovementTypeKey(InventoryMovementType type) {
  switch (type) {
    case InventoryMovementType.stockIn:
      return 'stock_in';
    case InventoryMovementType.stockOut:
      return 'stock_out';
    case InventoryMovementType.sale:
      return 'sale';
    case InventoryMovementType.saleReversal:
      return 'sale_reversal';
  }
}

class InventoryAdjustmentResult {
  const InventoryAdjustmentResult({
    required this.success,
    this.errorMessage,
    this.newQty,
  });

  final bool success;
  final String? errorMessage;
  final int? newQty;
}

CollectionReference<Map<String, dynamic>> get inventoryMovementsCollection =>
    FirebaseFirestore.instance.collection('inventory_movements');

Future<InventoryAdjustmentResult> adjustProductStock({
  required DocumentReference productRef,
  required int delta,
  required InventoryMovementType type,
  String? note,
  DocumentReference? orderRef,
}) async {
  if (delta == 0) {
    return const InventoryAdjustmentResult(
      success: false,
      errorMessage: 'Quantity must not be zero.',
    );
  }

  try {
    final newQty = await FirebaseFirestore.instance.runTransaction<int>(
      (tx) async {
        final productSnap = await tx.get(productRef);
        if (!productSnap.exists) {
          throw StateError('Product not found.');
        }
        final data =
            (productSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        final trackStock = data['trackStock'] as bool? ?? true;
        if (!trackStock) {
          throw StateError('Stock tracking is disabled for this product.');
        }

      final current = (data['stockQty'] as num?)?.toInt() ?? 0;
      final next = current + delta;
      if (next < 0) {
        throw StateError('Insufficient stock (current: $current).');
      }

        tx.update(productRef, {'stockQty': next});

        final movementRef = inventoryMovementsCollection.doc();
        tx.set(movementRef, {
          'companyRef': data['companyRef'],
          'productRef': productRef,
          if (orderRef != null) 'orderRef': orderRef,
          'type': inventoryMovementTypeKey(type),
          'delta': delta,
          'qty_before': current,
          'qty_after': next,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          'created_by_uid': currentUserUid,
          'created_time': FieldValue.serverTimestamp(),
        });

        return next;
      },
    );

    return InventoryAdjustmentResult(success: true, newQty: newQty);
  } catch (error) {
    return InventoryAdjustmentResult(
      success: false,
      errorMessage: describeFirestoreError(error),
    );
  }
}

Future<InventoryAdjustmentResult> recordStockIn({
  required DocumentReference productRef,
  required int qty,
  String? note,
}) =>
    adjustProductStock(
      productRef: productRef,
      delta: qty,
      type: InventoryMovementType.stockIn,
      note: note,
    );

Future<InventoryAdjustmentResult> recordStockOut({
  required DocumentReference productRef,
  required int qty,
  String? note,
}) =>
    adjustProductStock(
      productRef: productRef,
      delta: -qty,
      type: InventoryMovementType.stockOut,
      note: note,
    );

Future<void> deductStockForOrder(DocumentReference orderRef) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  if (order.stockDeducted) {
    return;
  }

  final items = activeOrderItems(await queryOrderItemsForOrderOnce(orderRef));
  if (items.isEmpty) {
    return;
  }

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final orderSnap = await tx.get(orderRef);
    final orderData =
        (orderSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (orderData['stock_deducted'] == true) {
      return;
    }

    for (final item in items) {
      final productRef = item.productRef;
      if (productRef == null) {
        continue;
      }
      final qty = item.qty > 0 ? item.qty : 0;
      if (qty <= 0) {
        continue;
      }

      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        continue;
      }
      final productData =
          (productSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
      final trackStock = productData['trackStock'] as bool? ?? true;
      if (!trackStock) {
        continue;
      }

      final current = (productData['stockQty'] as num?)?.toInt() ?? 0;
      final next = current - qty;
      final allowZeroStock = productData['allowZeroStock'] as bool? ?? false;
      if (next < 0 && !allowZeroStock) {
        throw StateError(
          'Insufficient stock for ${item.name.isNotEmpty ? item.name : 'product'} '
          '(need $qty, have $current).',
        );
      }

      tx.update(productRef, {'stockQty': next});

      final movementRef = inventoryMovementsCollection.doc();
      tx.set(movementRef, {
        'companyRef': orderData['companyRef'] ?? productData['companyRef'],
        'productRef': productRef,
        'orderRef': orderRef,
        'type': inventoryMovementTypeKey(InventoryMovementType.sale),
        'delta': -qty,
        'qty_before': current,
        'qty_after': next,
        'order_item_ref': item.reference,
        'created_by_uid': currentUserUid,
        'created_time': FieldValue.serverTimestamp(),
      });
    }

    tx.update(orderRef, {'stock_deducted': true});
  });
}

Future<void> restoreStockForOrder(DocumentReference orderRef) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  if (!order.stockDeducted) {
    return;
  }

  final items = activeOrderItems(await queryOrderItemsForOrderOnce(orderRef));

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final orderSnap = await tx.get(orderRef);
    final orderData =
        (orderSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (orderData['stock_deducted'] != true) {
      return;
    }

    for (final item in items) {
      final productRef = item.productRef;
      if (productRef == null) {
        continue;
      }
      final qty = item.qty > 0 ? item.qty : 0;
      if (qty <= 0) {
        continue;
      }

      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) {
        continue;
      }
      final productData =
          (productSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
      final trackStock = productData['trackStock'] as bool? ?? true;
      if (!trackStock) {
        continue;
      }

      final current = (productData['stockQty'] as num?)?.toInt() ?? 0;
      final next = current + qty;
      tx.update(productRef, {'stockQty': next});

      final movementRef = inventoryMovementsCollection.doc();
      tx.set(movementRef, {
        'companyRef': orderData['companyRef'] ?? productData['companyRef'],
        'productRef': productRef,
        'orderRef': orderRef,
        'type': inventoryMovementTypeKey(InventoryMovementType.saleReversal),
        'delta': qty,
        'qty_before': current,
        'qty_after': next,
        'order_item_ref': item.reference,
        'created_by_uid': currentUserUid,
        'created_time': FieldValue.serverTimestamp(),
      });
    }

    tx.update(orderRef, {'stock_deducted': false});
  });
}

Future<void> freezeOrderInventory(DocumentReference orderRef) async {
  await orderRef.update(
    createOrdersRecordData(inventoryFrozen: true),
  );
}

Future<void> applyInventoryOnOrderPayment(DocumentReference orderRef) async {
  try {
    await deductStockForOrder(orderRef);
  } catch (error) {
    throw StateError(describeFirestoreError(error));
  }
}

Future<void> applyInventoryOnOrderCompleted(DocumentReference orderRef) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  if (!order.stockDeducted) {
    await deductStockForOrder(orderRef);
  }
}

Future<void> applyInventoryOnOrderCancelled(DocumentReference orderRef) async {
  await restoreStockForOrder(orderRef);
}
