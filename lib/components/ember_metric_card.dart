import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/theme/ember_brand.dart';

class EmberMetricCard extends StatelessWidget {
  const EmberMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.highlight = false,
    this.onTap,
    this.loading = false,
  });

  final String label;
  final Widget value;
  final IconData? icon;
  final Color? accentColor;
  final bool highlight;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ??
        (highlight ? EmberBrand.amber : EmberBrand.electricBlue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EmberBrand.radiusLg),
        child: Container(
          decoration: EmberBrand.cardDecoration(
            border: Border.all(
              color: highlight
                  ? EmberBrand.amber.withValues(alpha: 0.35)
                  : EmberBrand.border,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 22),
                const SizedBox(height: 14),
              ],
              if (loading)
                const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                DefaultTextStyle(
                  style: GoogleFonts.interTight(
                    fontSize: highlight ? 30 : 28,
                    fontWeight: FontWeight.w700,
                    color: highlight ? EmberBrand.amber : EmberBrand.textPrimary,
                  ),
                  child: value,
                ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: EmberBrand.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
