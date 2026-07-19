import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/components/ember_form_field.dart';
import '/theme/ember_brand.dart';

Future<void> _runQtyMutation(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update quantity: $error')),
    );
  }
}

/// +/- controls and editable qty for checkout summary rows.
class OrderItemQtyStepper extends StatefulWidget {
  const OrderItemQtyStepper({
    super.key,
    required this.item,
    required this.orderRef,
  });

  final OrderItemRecord item;
  final DocumentReference orderRef;

  @override
  State<OrderItemQtyStepper> createState() => _OrderItemQtyStepperState();
}

class _OrderItemQtyStepperState extends State<OrderItemQtyStepper> {
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.qty.toString());
    _qtyFocus.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(OrderItemQtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty && !_editing) {
      _qtyController.text = widget.item.qty.toString();
    }
  }

  @override
  void dispose() {
    _qtyFocus.removeListener(_handleFocusChange);
    _qtyFocus.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_qtyFocus.hasFocus && _editing) {
      _editing = false;
      _applyTypedQty();
    }
  }

  Future<void> _applyTypedQty() async {
    final parsed = int.tryParse(_qtyController.text.trim());
    if (parsed == null) {
      _qtyController.text = widget.item.qty.toString();
      return;
    }
    if (parsed == widget.item.qty) {
      return;
    }
    await _runQtyMutation(
      context,
      () => setOrderItemQuantity(
        item: widget.item,
        orderRef: widget.orderRef,
        qty: parsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.item.qty >= 1)
          _QtyIconButton(
            icon: Icons.remove,
            background: EmberBrand.border,
            foreground: EmberBrand.textPrimary,
            onPressed: () => _runQtyMutation(
              context,
              () => decreaseOrderItemQuantityOrDelete(
                item: widget.item,
                orderRef: widget.orderRef,
              ),
            ),
          ),
        Container(
          width: 48.0,
          height: 32.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: EmberBrand.background,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: EmberBrand.border),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _qtyController,
            focusNode: _qtyFocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EmberBrand.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => _editing = true,
            onSubmitted: (_) {
              _editing = false;
              _applyTypedQty();
            },
          ),
        ),
        _QtyIconButton(
          icon: Icons.add,
          background: EmberBrand.navy,
          foreground: Colors.white,
          onPressed: () => _runQtyMutation(
            context,
            () => increaseOrderItemQuantity(
              item: widget.item,
              orderRef: widget.orderRef,
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: foreground),
        ),
      ),
    );
  }
}

/// Qty field with +/- for order edit forms (controller-driven).
class OrderItemQtyFieldStepper extends StatelessWidget {
  const OrderItemQtyFieldStepper({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool enabled;

  void _bump(int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next <= 0) {
      return;
    }
    controller.text = next.toString();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: !enabled ? null : () => _bump(-1),
          icon: const Icon(
            Icons.remove_circle_outline,
            color: EmberBrand.textSecondary,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: emberFormFieldTextStyle(context),
            decoration: emberFormInputDecoration(
              context,
              labelText: 'Qty',
            ).copyWith(isDense: true),
            onChanged: (_) => onChanged(),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: !enabled ? null : () => _bump(1),
          icon: const Icon(
            Icons.add_circle_outline,
            color: EmberBrand.navy,
          ),
        ),
      ],
    );
  }
}
