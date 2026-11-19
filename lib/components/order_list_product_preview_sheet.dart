import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_item_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/components/order_detail_item_tile.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

Future<void> showOrderListProductPreviewSheet(
  BuildContext context, {
  required OrdersRecord order,
  required List<OrderItemRecord> items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _OrderListProductPreviewSheet(
      order: order,
      items: items,
    ),
  );
}

class _OrderListProductPreviewSheet extends StatelessWidget {
  const _OrderListProductPreviewSheet({
    required this.order,
    required this.items,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final visibleItems = activeOrderItems(items);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'order.preview.productsTitle'),
                style: theme.titleLarge.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${orderListOrderId(order)} · ${orderListCustomer(order)}',
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: visibleItems.isEmpty
                    ? Center(
                        child: Text(
                          tr(context, 'order.preview.noProducts'),
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 20,
                          thickness: 1,
                          color: theme.alternate,
                        ),
                        itemBuilder: (context, index) {
                          return OrderDetailItemTile(
                            item: visibleItems[index],
                            items: visibleItems,
                            order: order,
                            showCopyableCard: !isRetailOrderRecord(order),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
