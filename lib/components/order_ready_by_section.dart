import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_ready_by_helpers.dart';
import '/components/assign_ready_by_sheet.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/l10n/tr.dart';

/// Ready by staff on order detail. Separate from assigned driver.
class OrderReadyBySection extends StatelessWidget {
  const OrderReadyBySection({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  Future<void> _openPicker(BuildContext context) {
    return showAssignReadyBySheet(context, order: order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canAssign = canAssignReadyBy(AppStateNotifier.instance.userRole);
    final readyBy = order.readyBy;

    Widget body;
    if (readyBy == null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ReadyByChip(
            label: tr(context, 'order.readyBy.unassigned'),
            color: readyByStaffColor(null),
          ),
        ],
      );
    } else {
      body = StreamBuilder<UsersRecord>(
        stream: UsersRecord.getDocument(readyBy),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user == null
              ? readyBy.id
              : readyByDisplayName(user);
          final color = user == null
              ? readyByStaffColor(readyBy.id)
              : readyByStaffColor(readyByStaffKey(user));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ReadyByChip(label: name, color: color),
            ],
          );
        },
      );
    }

    final row = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              tr(context, 'order.readyBy.label'),
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Flexible(child: body),
        ],
      ),
    );

    if (!canAssign) {
      return row;
    }

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

class _ReadyByChip extends StatelessWidget {
  const _ReadyByChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
