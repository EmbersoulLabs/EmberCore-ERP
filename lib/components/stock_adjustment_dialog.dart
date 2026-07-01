import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/inventory_service.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

Future<bool> showStockAdjustmentDialog(
  BuildContext context, {
  required ProductRecord product,
  required bool stockIn,
}) async {
  final qtyController = TextEditingController();
  final noteController = TextEditingController();
  var submitting = false;
  String? errorText;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(
            stockIn
                ? tr(context, 'product.stock.stockInTitle')
                : tr(context, 'product.stock.stockOutTitle'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.name,
                style: FlutterFlowTheme.of(context).titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                tr(
                  context,
                  'product.stock.currentQty',
                  params: {'qty': '${product.stockQty}'},
                ),
                style: FlutterFlowTheme.of(context).bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: tr(context, 'product.stock.qty'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: tr(context, 'product.stock.noteOptional'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        color: FlutterFlowTheme.of(context).error,
                      ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: Text(tr(context, 'common.cancel')),
            ),
            TextButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                      if (qty <= 0) {
                        setDialogState(() {
                          errorText = tr(context, 'product.stock.qtyRequired');
                        });
                        return;
                      }
                      setDialogState(() {
                        submitting = true;
                        errorText = null;
                      });
                      final result = stockIn
                          ? await recordStockIn(
                              productRef: product.reference,
                              qty: qty,
                              note: noteController.text,
                            )
                          : await recordStockOut(
                              productRef: product.reference,
                              qty: qty,
                              note: noteController.text,
                            );
                      if (!dialogContext.mounted) {
                        return;
                      }
                      if (!result.success) {
                        setDialogState(() {
                          submitting = false;
                          errorText = result.errorMessage;
                        });
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      stockIn
                          ? tr(context, 'product.stock.stockInConfirm')
                          : tr(context, 'product.stock.stockOutConfirm'),
                    ),
            ),
          ],
        );
      },
    ),
  );

  qtyController.dispose();
  noteController.dispose();
  return confirmed == true;
}
