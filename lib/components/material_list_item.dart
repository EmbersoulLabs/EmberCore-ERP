import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/create_order_service.dart';
import '/backend/material_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/material_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Material catalog row matching the product list card layout.
class MaterialListItem extends StatefulWidget {
  const MaterialListItem({
    super.key,
    required this.material,
  });

  final MaterialRecord material;

  @override
  State<MaterialListItem> createState() => _MaterialListItemState();
}

class _MaterialListItemState extends State<MaterialListItem> {
  bool _deleting = false;

  MaterialRecord get material => widget.material;

  void _openMaterialEdit(BuildContext context) {
    if (_deleting) {
      return;
    }
    context.pushNamed(
      MaterialcreateWidget.routeName,
      queryParameters: {
        'materialRef': serializeParam(
          material.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (_deleting) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'material.delete.title')),
        content: Text(
          tr(
            context,
            'material.delete.body',
            params: {'name': material.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'material.delete.button')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      final error = await deleteMaterialRecord(material);
      if (!mounted) {
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'material.delete.failed', params: {'error': error}),
            ),
            duration: const Duration(seconds: 8),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'material.delete.success',
              params: {'name': material.name},
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'material.delete.failed',
              params: {'error': describeFirestoreError(error)},
            ),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final costText = material.cost.truncateToDouble() == material.cost
        ? material.cost.toStringAsFixed(0)
        : material.cost.toStringAsFixed(2);
    final active = material.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
      child: Material(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openMaterialEdit(context),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: theme.alternate),
            ),
            child: Opacity(
              opacity: active ? 1 : 0.72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildZoomableProductImage(
                      context: context,
                      imageUrl: materialImageFromRecord(material),
                      productRef: material.reference,
                      title: material.name,
                      width: 68.0,
                      height: 68.0,
                      storageFolderPrefix: kMaterialImagesFolder,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                              height: 1.25,
                            ),
                          ),
                          if (material.sku.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Text(
                                'SKU ${material.sku}',
                                style: GoogleFonts.inter(
                                  fontSize: 12.0,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6.0),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _MetaChip(
                                label: '\$$costText',
                                color: theme.primary,
                              ),
                              if (material.unit.isNotEmpty)
                                _MetaChip(
                                  label: material.unit,
                                  color: theme.secondaryText,
                                ),
                              _MetaChip(
                                label: active
                                    ? tr(context, 'common.active')
                                    : tr(context, 'common.inactive'),
                                color: active
                                    ? const Color(0xFF2E7D32)
                                    : theme.secondaryText,
                              ),
                              if (material.category.isNotEmpty)
                                _MetaChip(
                                  label: material.category,
                                  color: theme.tertiary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_deleting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      IconButton(
                        tooltip: tr(context, 'material.delete.tooltip'),
                        icon: Icon(Icons.delete_outline, color: theme.error),
                        onPressed: () => _confirmDelete(context),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.secondaryText,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
