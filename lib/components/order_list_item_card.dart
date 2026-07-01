import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/responsive_layout_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/components/order_list_driver_cell.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

/// Single order row for [Orderlist1Widget] with the requested columns.
class OrderListItemCard extends StatelessWidget {
  const OrderListItemCard({
    super.key,
    required this.order,
    required this.items,
    required this.locale,
    required this.checked,
    required this.onCheckedChanged,
    required this.onTap,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final String? locale;
  final bool checked;
  final ValueChanged<bool?> onCheckedChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusColor = orderListStatusColor(order.status);
    final statusLabel = orderListStatusLabel(context, order);
    final paymentLabel = orderListPaymentStatus(context, order);
    final paymentColor = order.balanceDue > 0.009
        ? EmberBrand.amber
        : EmberBrand.teal;
    final cells = <String>[
      orderListOrderId(order),
      orderListCustomer(order),
      orderListPhone(order),
      orderListPickupDelivery(context, order),
      orderListDeliveryDateOnly(order, locale: locale),
      orderListDeliveryTimeSlot(order),
      statusLabel,
      paymentLabel,
      '',
      orderListTotal(order),
      tr(context, 'order.col.view'),
    ];

    return Material(
      color: EmberBrand.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: EmberBrand.border, width: 1.0),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6.0, 10.0, 8.0, 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged: onCheckedChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: EmberBrand.navy,
                checkColor: Colors.white,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final opsWide =
                        constraints.maxWidth >= kOrderListOpsBreakpoint;
                    if (opsWide) {
                      return _OpsWideRow(
                        order: order,
                        cells: cells,
                        statusColor: statusColor,
                        paymentColor: paymentColor,
                        theme: theme,
                        onView: onTap,
                      );
                    }
                    final wide =
                        constraints.maxWidth >= kOrderListTableBreakpoint;
                    if (wide) {
                      return _LegacyWideRow(
                        order: order,
                        items: items,
                        statusColor: statusColor,
                        statusLabel: statusLabel,
                        paymentLabel: paymentLabel,
                        paymentColor: paymentColor,
                        locale: locale,
                        theme: theme,
                      );
                    }
                    return _NarrowColumn(
                      order: order,
                      items: items,
                      statusColor: statusColor,
                      statusLabel: statusLabel,
                      paymentLabel: paymentLabel,
                      paymentColor: paymentColor,
                      locale: locale,
                      theme: theme,
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

class OrderListTableHeader extends StatelessWidget {
  const OrderListTableHeader({
    super.key,
    this.selectAllValue,
    this.onSelectAllChanged,
  });

  final bool? selectAllValue;
  final ValueChanged<bool?>? onSelectAllChanged;

  @override
  Widget build(BuildContext context) {
    final columns = orderListColumnLabels(context);
    return Container(
      color: EmberBrand.background,
      padding: const EdgeInsets.fromLTRB(6.0, 8.0, 8.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            tristate: true,
            value: selectAllValue,
            onChanged: onSelectAllChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            activeColor: EmberBrand.navy,
            checkColor: Colors.white,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final opsWide =
                    constraints.maxWidth >= kOrderListOpsBreakpoint;
                if (opsWide) {
                  return Row(
                    children: [
                      for (var i = 0; i < columns.length; i++)
                        Expanded(
                          flex: _columnFlex(i),
                          child: _headerCell(context, columns[i]),
                        ),
                    ],
                  );
                }
                return Text(
                  columns.join(' · '),
                  style: _headerStyle(context).copyWith(fontSize: 11.0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: EmberBrand.textSecondary,
        letterSpacing: 0.2,
      );

  Widget _headerCell(BuildContext context, String label) => Text(
        label,
        style: _headerStyle(context),
      );
}

int _columnFlex(int index) {
  switch (index) {
    case 0:
      return 3;
    case 1:
    case 2:
      return 2;
    case 3:
      return 1;
    case 4:
    case 5:
      return 2;
    case 6:
    case 7:
    case 8:
      return 2;
    case 9:
      return 2;
    case 10:
      return 1;
    default:
      return 1;
  }
}

class _OpsWideRow extends StatelessWidget {
  const _OpsWideRow({
    required this.order,
    required this.cells,
    required this.statusColor,
    required this.paymentColor,
    required this.theme,
    required this.onView,
  });

  final OrdersRecord order;
  final List<String> cells;
  final Color statusColor;
  final Color paymentColor;
  final FlutterFlowTheme theme;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: _columnFlex(i),
            child: switch (i) {
              6 => _StatusChip(label: cells[i], color: statusColor),
              7 => _StatusChip(label: cells[i], color: paymentColor),
              8 => OrderListDriverCell(order: order, theme: theme),
              10 => IconButton(
                  onPressed: onView,
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  color: EmberBrand.electricBlue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              _ => _CellText(
                  text: cells[i],
                  bold: i == 0,
                  theme: theme,
                ),
            },
          ),
      ],
    );
  }
}

class _LegacyWideRow extends StatelessWidget {
  const _LegacyWideRow({
    required this.order,
    required this.items,
    required this.statusColor,
    required this.statusLabel,
    required this.paymentLabel,
    required this.paymentColor,
    required this.locale,
    required this.theme,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final Color statusColor;
  final String statusLabel;
  final String paymentLabel;
  final Color paymentColor;
  final String? locale;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _CellText(
                text: orderListOrderId(order),
                bold: true,
                theme: theme,
              ),
            ),
            _StatusChip(label: statusLabel, color: statusColor),
          ],
        ),
        const SizedBox(height: 4),
        _CellText(
          text:
              '${orderListCustomer(order)} · ${orderListPhone(order)} · ${orderListTotal(order)}',
          theme: theme,
        ),
        _CellText(
          text:
              '${orderListPickupDelivery(context, order)} · ${orderListDeliveryDate(order, locale: locale)}',
          theme: theme,
        ),
        _CellText(
          text: orderListProductSummaryLocalized(context, items),
          theme: theme,
        ),
        const SizedBox(height: 4),
        _StatusChip(label: paymentLabel, color: paymentColor),
      ],
    );
  }
}

class _NarrowColumn extends StatelessWidget {
  const _NarrowColumn({
    required this.order,
    required this.items,
    required this.statusColor,
    required this.statusLabel,
    required this.paymentLabel,
    required this.paymentColor,
    required this.locale,
    required this.theme,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final Color statusColor;
  final String statusLabel;
  final String paymentLabel;
  final Color paymentColor;
  final String? locale;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                orderListOrderId(order),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StatusChip(label: statusLabel, color: statusColor),
          ],
        ),
        const SizedBox(height: 3),
        _compactLine(tr(context, 'order.col.customer'), orderListCustomer(order)),
        _compactLine(tr(context, 'order.col.phone'), orderListPhone(order)),
        _compactLine(
          tr(context, 'order.col.deliveryDate'),
          orderListDeliveryDate(order, locale: locale),
        ),
        _compactLine(
          tr(context, 'order.col.paymentStatus'),
          paymentLabel,
        ),
        if (!isRetailOrderRecord(order))
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(context, 'order.col.driver')}: ',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                  ),
                ),
                Expanded(
                  child: OrderListDriverCell(
                    order: order,
                    theme: theme,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        _compactLine(tr(context, 'order.col.total'), orderListTotal(order)),
        _compactLine(
          tr(context, 'order.col.product'),
          orderListProductSummaryLocalized(context, items),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _compactLine(String label, String value, {int maxLines = 1}) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 11.5,
            height: 1.25,
            color: theme.primaryText,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText({
    required this.text,
    required this.theme,
    this.bold = false,
  });

  final String text;
  final FlutterFlowTheme theme;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: bold ? 14.0 : 13.0,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: theme.primaryText,
        height: 1.35,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
