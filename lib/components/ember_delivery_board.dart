import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/theme/ember_brand.dart';

/// Delivery operations board section (Unassigned / Assigned / etc.).
class EmberDeliveryGroupSection extends StatelessWidget {
  const EmberDeliveryGroupSection({
    super.key,
    required this.title,
    required this.count,
    required this.child,
    this.accentColor,
  });

  final String title;
  final int count;
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? EmberBrand.electricBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: EmberBrand.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.interTight(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: EmberBrand.navy,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: EmberBrand.border),
          child,
        ],
      ),
    );
  }
}
