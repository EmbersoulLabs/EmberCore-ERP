import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/theme/ember_brand.dart';

class EmberBulkActionBar extends StatelessWidget {
  const EmberBulkActionBar({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: EmberBrand.card,
        border: Border(top: BorderSide(color: EmberBrand.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x080A2540),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ),
    );
  }
}

class EmberBulkButton extends StatelessWidget {
  const EmberBulkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = EmberBulkButtonVariant.primary,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EmberBulkButtonVariant variant;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color borderColor;

    switch (variant) {
      case EmberBulkButtonVariant.primary:
        bg = EmberBrand.navy;
        fg = Colors.white;
        borderColor = EmberBrand.navy;
        break;
      case EmberBulkButtonVariant.secondary:
        bg = EmberBrand.card;
        fg = EmberBrand.navy;
        borderColor = EmberBrand.border;
        break;
      case EmberBulkButtonVariant.success:
        bg = EmberBrand.teal;
        fg = Colors.white;
        borderColor = EmberBrand.teal;
        break;
      case EmberBulkButtonVariant.danger:
        bg = EmberBrand.error;
        fg = Colors.white;
        borderColor = EmberBrand.error;
        break;
    }

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18, color: enabled ? fg : EmberBrand.textSecondary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? fg : EmberBrand.textSecondary,
        backgroundColor: enabled ? bg : EmberBrand.background,
        side: BorderSide(color: enabled ? borderColor : EmberBrand.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum EmberBulkButtonVariant { primary, secondary, success, danger }
