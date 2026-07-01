import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/driver_assignment_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/users_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

/// Driver name for order list rows; updates live when assignment changes.
class OrderListDriverCell extends StatelessWidget {
  const OrderListDriverCell({
    super.key,
    required this.order,
    this.theme,
    this.bold = false,
    this.compact = false,
  });

  final OrdersRecord order;
  final FlutterFlowTheme? theme;
  final bool bold;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? FlutterFlowTheme.of(context);
    final baseStyle = GoogleFonts.inter(
      fontSize: compact ? 11.5 : (bold ? 14.0 : 13.0),
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: effectiveTheme.primaryText,
      height: compact ? 1.25 : 1.35,
    );

    if (isRetailOrderRecord(order)) {
      return Text('—', style: baseStyle);
    }

    if (!order.hasAssignedDriver()) {
      return Text(
        tr(context, 'order.field.unassignedDriver'),
        style: baseStyle.copyWith(
          color: EmberBrand.amber,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(order.assignedDriver!),
      builder: (context, snapshot) {
        final label = snapshot.hasData
            ? driverDisplayName(snapshot.data!)
            : '…';
        return Text(label, style: baseStyle);
      },
    );
  }
}
