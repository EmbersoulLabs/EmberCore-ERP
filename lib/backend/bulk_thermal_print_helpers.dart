import 'package:flutter/material.dart';

import '/backend/order_item_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/custom_code/bluetooth_receipt_printer.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

/// Delivery / pickup orders eligible for thermal delivery-slip printing.
bool isThermalDeliveryPrintableOrder(OrdersRecord order) {
  if (isRetailOrderRecord(order)) {
    return false;
  }
  return orderMatchesOrderListType(order, 'Delivery') ||
      orderMatchesOrderListType(order, 'PickUp');
}

/// Batch-print full thermal delivery slips for selected orders.
///
/// Defaults to **full delivery** (all active line items). Skips retail orders.
/// Requires a saved Bluetooth printer (prompts once if missing).
Future<void> bulkPrintThermalDeliveryOrders(
  BuildContext context, {
  required List<OrdersRecord> orders,
}) async {
  if (!BluetoothReceiptPrinter.isBluetoothPrintAvailable) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BluetoothReceiptPrinter.unsupportedPlatformMessage()),
        ),
      );
    }
    return;
  }

  final printable = orders.where(isThermalDeliveryPrintableOrder).toList();
  if (printable.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.bulk.printThermalNone')),
        ),
      );
    }
    return;
  }

  final skippedRetail = orders.length - printable.length;
  var printed = 0;
  var failed = 0;

  for (final order in printable) {
    if (!context.mounted) {
      return;
    }
    final items = activeOrderItems(
      await queryOrderItemsForOrderOnce(order.reference),
    );
    if (items.isEmpty) {
      failed++;
      continue;
    }
    final ok = await BluetoothReceiptPrinter.printDeliverySlip(
      context,
      order: order,
      items: items,
    );
    if (ok) {
      printed++;
    } else {
      failed++;
      // Stop on first hard failure so user can fix printer without flooding.
      break;
    }
  }

  if (!context.mounted) {
    return;
  }

  final theme = FlutterFlowTheme.of(context);
  final parts = <String>[
    tr(
      context,
      'order.bulk.printThermalResult',
      params: {
        'printed': '$printed',
        'total': '${printable.length}',
      },
    ),
  ];
  if (skippedRetail > 0) {
    parts.add(
      tr(
        context,
        'order.bulk.printThermalSkippedRetail',
        params: {'count': '$skippedRetail'},
      ),
    );
  }
  if (failed > 0) {
    parts.add(
      tr(
        context,
        'order.bulk.printThermalFailed',
        params: {'count': '$failed'},
      ),
    );
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(parts.join(' ')),
      backgroundColor: failed > 0 ? theme.error : theme.secondary,
      duration: const Duration(seconds: 5),
    ),
  );
}
