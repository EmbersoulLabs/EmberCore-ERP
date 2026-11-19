import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/product_category_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

Future<void> updateProductCategory(
  DocumentReference productRef,
  String category,
) async {
  await productRef.update(
    createProductRecordData(
      category: normalizeProductCategoryName(category),
    ),
  );
}

Future<int> bulkUpdateProductCategory({
  required Iterable<ProductRecord> products,
  required String category,
}) async {
  final normalized = normalizeProductCategoryName(category);
  var updated = 0;
  for (final product in products) {
    await product.reference.update(
      createProductRecordData(category: normalized),
    );
    updated++;
  }
  return updated;
}

Future<int> bulkDeleteProducts(Iterable<ProductRecord> products) async {
  var deleted = 0;
  for (final product in products) {
    await deleteProductRecord(product);
    deleted++;
  }
  return deleted;
}

/// Picks a category for bulk update. Returns null if cancelled.
Future<String?> showBulkChangeProductCategoryDialog(
  BuildContext context, {
  required List<String> categories,
}) async {
  String? selected =
      categories.isNotEmpty ? categories.first : null;
  final customController = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(tr(context, 'product.bulk.changeCategoryTitle')),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (categories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selected != null && categories.contains(selected)
                          ? selected
                          : categories.first,
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selected = value);
                      },
                      decoration: InputDecoration(
                        labelText: tr(context, 'product.form.category'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customController,
                    decoration: InputDecoration(
                      labelText: tr(context, 'product.bulk.newCategoryHint'),
                    ),
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        setDialogState(() => selected = value.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(tr(context, 'common.cancel')),
              ),
              TextButton(
                onPressed: () {
                  final custom = customController.text.trim();
                  final value = custom.isNotEmpty ? custom : selected;
                  if (value == null || value.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(dialogContext, value.trim());
                },
                child: Text(tr(context, 'common.save')),
              ),
            ],
          );
        },
      );
    },
  );

  customController.dispose();
  return result;
}

Future<bool> confirmBulkDeleteProducts(
  BuildContext context, {
  required int count,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr(context, 'product.bulk.deleteTitle')),
      content: Text(
        tr(
          context,
          'product.bulk.deleteBody',
          params: {'count': '$count'},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(tr(context, 'common.cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: FlutterFlowTheme.of(context).error,
          ),
          child: Text(tr(context, 'common.delete')),
        ),
      ],
    ),
  );
  return confirmed == true;
}
