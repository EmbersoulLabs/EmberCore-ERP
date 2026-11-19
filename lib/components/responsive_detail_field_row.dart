import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/responsive_layout_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Label + value row that stacks on phone and sits side-by-side on wider screens.
class ResponsiveDetailFieldRow extends StatelessWidget {
  const ResponsiveDetailFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.valueSecondary = false,
  });

  final String label;
  final String value;
  final bool valueSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final labelStyle = theme.bodyMedium.override(
      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
    );
    final valueStyle = theme.bodyMedium.override(
      font: GoogleFonts.inter(fontWeight: FontWeight.normal),
      color: valueSecondary ? theme.secondaryText : theme.primaryText,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kCompactBreakpoint;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 2),
              Text(value, style: valueStyle),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: valueStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
