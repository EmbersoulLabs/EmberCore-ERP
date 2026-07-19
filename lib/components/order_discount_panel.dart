import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/customer_invoice_helpers.dart';
import '/backend/order_discount_helpers.dart';
import '/components/ember_form_field.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

/// Shared % / SGD discount control for Retail and Delivery/Pick Up payment pages.
/// Editable only when [canEdit] is true (admin). Otherwise shows a read-only
/// summary when a discount is already on the order.
class OrderDiscountPanel extends StatelessWidget {
  const OrderDiscountPanel({
    super.key,
    required this.discountType,
    required this.discountController,
    required this.remarkController,
    required this.totals,
    required this.onTypeChanged,
    required this.onValueChanged,
    this.canEdit = false,
    this.existingRemark = '',
  });

  final CustomerInvoiceDiscountType discountType;
  final TextEditingController discountController;
  final TextEditingController remarkController;
  final OrderPayableTotals totals;
  final ValueChanged<CustomerInvoiceDiscountType> onTypeChanged;
  final VoidCallback onValueChanged;
  final bool canEdit;
  final String existingRemark;

  String _money(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    if (!canEdit && totals.discount <= 0.005) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: EmberBrand.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(context, 'pos.discount.title'),
            style: GoogleFonts.interTight(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EmberBrand.navy,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            SegmentedButton<CustomerInvoiceDiscountType>(
              segments: const [
                ButtonSegment(
                  value: CustomerInvoiceDiscountType.percent,
                  label: Text('%'),
                ),
                ButtonSegment(
                  value: CustomerInvoiceDiscountType.amount,
                  label: Text('SGD'),
                ),
              ],
              selected: {discountType},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                onTypeChanged(selection.first);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => onValueChanged(),
              style: emberFormFieldTextStyle(context),
              decoration: emberFormInputDecoration(
                context,
                labelText: tr(context, 'pos.discount.title'),
                hintText: discountType == CustomerInvoiceDiscountType.percent
                    ? tr(context, 'pos.discount.hintPercent')
                    : tr(context, 'pos.discount.hintAmount'),
              ).copyWith(isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: remarkController,
              maxLines: 2,
              onChanged: (_) => onValueChanged(),
              style: emberFormFieldTextStyle(context),
              decoration: emberFormInputDecoration(
                context,
                labelText: tr(context, 'pos.discount.remark'),
                hintText: tr(context, 'pos.discount.remarkHint'),
              ).copyWith(isDense: true),
            ),
          ] else if (existingRemark.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${tr(context, 'pos.discount.remark')}: ${existingRemark.trim()}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: EmberBrand.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _row(
            tr(context, 'pos.discount.subtotal'),
            _money(totals.subtotal),
          ),
          const SizedBox(height: 6),
          _row(
            tr(
              context,
              'pos.discount.line',
              params: {'label': totals.discountLabel},
            ),
            totals.discount > 0 ? '-${_money(totals.discount)}' : _money(0),
          ),
          const Divider(height: 20, color: EmberBrand.border),
          _row(
            tr(context, 'pos.discount.payable'),
            _money(totals.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
  }) {
    final weight = bold ? FontWeight.w700 : FontWeight.w500;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: weight,
              color: EmberBrand.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: weight,
            color: EmberBrand.textPrimary,
          ),
        ),
      ],
    );
  }
}
