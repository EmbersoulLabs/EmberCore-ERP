import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

/// Number field that notifies [onCommitted] only on keyboard Done / confirm.
///
/// Typing does not rebuild the parent, so a phone keyboard stays open.
class CommitOnDoneNumericField extends StatefulWidget {
  const CommitOnDoneNumericField({
    super.key,
    required this.controller,
    required this.onCommitted,
    this.enabled = true,
    this.decimal = false,
    this.textAlign = TextAlign.start,
    this.decoration = const InputDecoration(),
    this.style,
    this.showSuffixConfirm = true,
  });

  final TextEditingController controller;
  final VoidCallback onCommitted;
  final bool enabled;
  final bool decimal;
  final TextAlign textAlign;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool showSuffixConfirm;

  @override
  State<CommitOnDoneNumericField> createState() =>
      _CommitOnDoneNumericFieldState();
}

class _CommitOnDoneNumericFieldState extends State<CommitOnDoneNumericField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
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
    if (mounted) {
      setState(() => _focused = hasFocus);
    } else {
      _focused = hasFocus;
    }
  }

  void _commit() {
    final raw = widget.controller.text.trim();
    if (raw.isNotEmpty) {
      final parsed = widget.decimal ? double.tryParse(raw) : int.tryParse(raw);
      if (parsed == null) {
        return;
      }
    }
    _focus.unfocus();
    widget.onCommitted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    var decoration = widget.decoration;
    if (widget.showSuffixConfirm && _focused && widget.enabled) {
      decoration = decoration.copyWith(
        suffixIcon: IconButton(
          tooltip: tr(context, 'common.confirm'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: _commit,
          icon: Icon(Icons.check_circle, color: theme.primary, size: 20),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      );
    }

    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      textAlign: widget.textAlign,
      style: widget.style,
      keyboardType: widget.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        if (widget.decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: decoration,
      onTapOutside: (_) {},
      onSubmitted: (_) => _commit(),
    );
  }
}
