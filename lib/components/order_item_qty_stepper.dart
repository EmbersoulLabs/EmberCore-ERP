import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/order_item_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

Future<void> _runQtyMutation(
  BuildContext context,
  Future<void> Function() action, {
  VoidCallback? onChanged,
}) async {
  try {
    await action();
    onChanged?.call();
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
    this.onChanged,
  });

  final OrderItemRecord item;
  final DocumentReference orderRef;
  final VoidCallback? onChanged;

  @override
  State<OrderItemQtyStepper> createState() => _OrderItemQtyStepperState();
}

class _OrderItemQtyStepperState extends State<OrderItemQtyStepper> {
  late final TextEditingController _qtyController;
  final FocusNode _qtyFocus = FocusNode();
  bool _editing = false;
  bool _committing = false;

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
    if (_qtyFocus.hasFocus) {
      _editing = true;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final wasEditing = _editing;
    _editing = false;
    if (wasEditing && !_committing) {
      _qtyController.text = widget.item.qty.toString();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _commitTypedQty() {
    _committing = true;
    _applyTypedQty();
    _qtyFocus.unfocus();
    _committing = false;
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
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.item.qty >= 1)
          FlutterFlowIconButton(
            borderRadius: 16.0,
            buttonSize: 32.0,
            fillColor: theme.alternate,
            icon: Icon(
              Icons.remove,
              color: theme.primaryText,
              size: 16.0,
            ),
            onPressed: () => _runQtyMutation(
              context,
              () => decreaseOrderItemQuantityOrDelete(
                item: widget.item,
                orderRef: widget.orderRef,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        Container(
          width: 48.0,
          height: 32.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: theme.alternate,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _qtyController,
            focusNode: _qtyFocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.bodyMedium.override(
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onTapOutside: (_) {},
            onSubmitted: (_) => _commitTypedQty(),
          ),
        ),
        FlutterFlowIconButton(
          borderRadius: 16.0,
          buttonSize: 32.0,
          fillColor: theme.primary,
          icon: Icon(
            _qtyFocus.hasFocus ? Icons.check : Icons.add,
            color: theme.primaryBackground,
            size: 16.0,
          ),
          onPressed: _qtyFocus.hasFocus
              ? _commitTypedQty
              : () => _runQtyMutation(
                    context,
                    () => increaseOrderItemQuantity(
                      item: widget.item,
                      orderRef: widget.orderRef,
                    ),
                    onChanged: widget.onChanged,
                  ),
        ),
      ],
    );
  }
}

/// Qty field with +/- for order edit forms (controller-driven).
class OrderItemQtyFieldStepper extends StatefulWidget {
  const OrderItemQtyFieldStepper({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  State<OrderItemQtyFieldStepper> createState() =>
      _OrderItemQtyFieldStepperState();
}

class _OrderItemQtyFieldStepperState extends State<OrderItemQtyFieldStepper> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  bool _committing = false;
  late String _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.controller.text;
    _focus.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focus.hasFocus;
    if (_focused == hasFocus) {
      return;
    }
    if (hasFocus) {
      _snapshot = widget.controller.text;
    } else if (!_committing) {
      widget.controller.text = _snapshot;
    }
    if (mounted) {
      setState(() => _focused = hasFocus);
    } else {
      _focused = hasFocus;
    }
  }

  void _commit() {
    final parsed = int.tryParse(widget.controller.text.trim());
    if (parsed == null || parsed <= 0) {
      widget.controller.text = _snapshot;
      _focus.unfocus();
      return;
    }
    widget.controller.text = parsed.toString();
    final changed = widget.controller.text != _snapshot;
    _snapshot = widget.controller.text;
    _committing = true;
    _focus.unfocus();
    _committing = false;
    if (changed) {
      widget.onChanged();
    }
  }

  void _bump(int delta) {
    final current = int.tryParse(widget.controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next <= 0) {
      return;
    }
    widget.controller.text = next.toString();
    _snapshot = widget.controller.text;
    if (_focused) {
      _committing = true;
      _focus.unfocus();
      _committing = false;
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: !widget.enabled ? null : () => _bump(-1),
          icon: Icon(Icons.remove_circle_outline, color: theme.secondaryText),
        ),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Qty',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onTapOutside: (_) {},
            onSubmitted: (_) => _commit(),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: _focused ? tr(context, 'common.confirm') : null,
          onPressed: !widget.enabled
              ? null
              : (_focused ? _commit : () => _bump(1)),
          icon: Icon(
            _focused ? Icons.check_circle : Icons.add_circle_outline,
            color: theme.primary,
          ),
        ),
      ],
    );
  }
}
