import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

/// Bottom bulk actions for the product catalog list.
class BulkProductActionBar extends StatelessWidget {
  const BulkProductActionBar({
    super.key,
    required this.selectedCount,
    required this.onChangeCategory,
    required this.onDelete,
    this.busy = false,
  });

  final int selectedCount;
  final VoidCallback onChangeCategory;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final enabled = selectedCount > 0 && !busy;

    return Material(
      elevation: 8,
      color: theme.secondaryBackground,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.alternate)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(
                  context,
                  selectedCount > 0
                      ? 'product.bulk.selectedCount'
                      : 'product.bulk.noneSelected',
                  params: {'count': '$selectedCount'},
                ),
                style: theme.labelMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: enabled ? onChangeCategory : null,
                      icon: const Icon(Icons.category_outlined, size: 18),
                      label: Text(tr(context, 'product.bulk.changeCategory')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: enabled ? onDelete : null,
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline, size: 18),
                      label: Text(tr(context, 'common.delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
