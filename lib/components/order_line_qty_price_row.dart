import 'package:flutter/material.dart';

import '/backend/responsive_layout_helpers.dart';
import '/components/commit_on_done_numeric_field.dart';
import '/components/order_item_qty_stepper.dart';

/// Qty stepper + price field that stays compact on wide screens and stacks
/// vertically on narrow widths.
class OrderLineQtyPriceRow extends StatelessWidget {
  const OrderLineQtyPriceRow({
    super.key,
    required this.qtyController,
    required this.priceController,
    required this.onChanged,
    this.enabled = true,
    this.priceFilled = false,
    this.priceFillColor,
  });

  final TextEditingController qtyController;
  final TextEditingController priceController;
  final VoidCallback onChanged;
  final bool enabled;
  final bool priceFilled;
  final Color? priceFillColor;

  Widget _priceField(BuildContext context) {
    return CommitOnDoneNumericField(
      controller: priceController,
      enabled: enabled,
      decimal: true,
      onCommitted: onChanged,
      decoration: InputDecoration(
        labelText: 'Price',
        isDense: true,
        filled: priceFilled,
        fillColor: priceFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < kCompactBreakpoint;
        final qty = OrderItemQtyFieldStepper(
          controller: qtyController,
          enabled: enabled,
          onChanged: onChanged,
        );
        final price = _priceField(context);

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              qty,
              const SizedBox(height: 8),
              price,
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: kOrderLineQtyFieldWidth, child: qty),
            const SizedBox(width: 8),
            SizedBox(width: kOrderLinePriceFieldWidth, child: price),
          ],
        );
      },
    );
  }
}
