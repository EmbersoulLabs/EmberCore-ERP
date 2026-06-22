import 'package:flutter/material.dart';

/// EmberSoul Labs brand tokens for EmberCore.
abstract final class EmberBrand {
  static const Color navy = Color(0xFF0A2540);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color teal = Color(0xFF14B8A6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color error = Color(0xFFDC2626);

  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static const double sidebarBreakpoint = 1024;
  static const double sidebarWidth = 260;

  static BoxDecoration cardDecoration({
    Color? color,
    Border? border,
  }) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: border ?? Border.all(color: EmberBrand.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A2540),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      );

  static String formatMoney(double value) => '\$${value.toStringAsFixed(2)}';
}
