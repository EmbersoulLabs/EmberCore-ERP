import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/theme/ember_brand.dart';

class EmberSectionCard extends StatelessWidget {
  const EmberSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: EmberBrand.cardDecoration(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.interTight(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: EmberBrand.navy,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: EmberBrand.border),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class EmberDetailRow extends StatelessWidget {
  const EmberDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.boldValue = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool boldValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: EmberBrand.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: boldValue ? FontWeight.w700 : FontWeight.w400,
                color: valueColor ?? EmberBrand.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
