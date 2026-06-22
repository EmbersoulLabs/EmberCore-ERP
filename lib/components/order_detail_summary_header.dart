import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_list_display_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/components/ember_status_badge.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

class OrderDetailSummaryHeader extends StatelessWidget {
  const OrderDetailSummaryHeader({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final statusLabel = orderListStatusLabel(context, order);
    final statusColor = orderListStatusColor(status);
    final paymentLabel = orderListPaymentStatus(context, order);
    final paymentColor = order.balanceDue > 0.009
        ? EmberBrand.amber
        : EmberBrand.teal;

    return Container(
      decoration: EmberBrand.cardDecoration(
        border: Border.all(color: EmberBrand.navy.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderListOrderId(order),
                      style: GoogleFonts.interTight(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: EmberBrand.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.clientName.isNotEmpty
                          ? order.clientName
                          : tr(context, 'order.detail.unnamedCustomer'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: EmberBrand.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              EmberStatusBadge(
                label: statusLabel,
                status: status,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Metric(
                label: tr(context, 'order.field.paymentStatus'),
                value: paymentLabel,
                valueColor: paymentColor,
              ),
              _Metric(
                label: tr(context, 'order.field.total'),
                value: EmberBrand.formatMoney(order.total),
                valueColor: EmberBrand.navy,
                bold: true,
              ),
              _Metric(
                label: tr(context, 'order.col.pd'),
                value: orderListPickupDelivery(context, order),
              ),
              _Metric(
                label: tr(context, 'order.col.deliveryDate'),
                value: orderListDeliveryDate(
                  order,
                  locale: Localizations.localeOf(context).languageCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: EmberBrand.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? EmberBrand.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
