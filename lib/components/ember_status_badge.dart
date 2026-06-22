import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/enums/enums.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_status_colors.dart';

class EmberStatusBadge extends StatelessWidget {
  const EmberStatusBadge({
    super.key,
    required this.label,
    this.status,
    this.color,
  });

  final String label;
  final OrderStatus? status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? emberOrderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
