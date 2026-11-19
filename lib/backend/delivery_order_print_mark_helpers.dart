import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Visible staff remark after a Delivery Order slip is printed.
const kPrintedDeliveryOrderRemark = 'Printed DO';

bool orderHasPrintedDeliveryOrder(OrdersRecord order) => order.printedDo;

/// Marks the order after a successful Delivery Order print (thermal or PDF).
/// Idempotent — safe to call on reprints. Never throws (print UX first).
Future<void> markDeliveryOrderPrinted(DocumentReference orderRef) async {
  try {
    await orderRef.update(
      createOrdersRecordData(
        printedDo: true,
        printedDoAt: getCurrentTimestamp,
      ),
    );
  } catch (_) {
    // Keep print success even if the remark write fails (rules/offline).
  }
}
