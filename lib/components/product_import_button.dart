import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/backend/product_import_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

Future<void> showProductImportPreviewDialog(
  BuildContext context,
  ProductImportParseResult parseResult,
) async {
  final validRows =
      parseResult.rows.where((row) => row.isValid).toList(growable: false);
  final previewRows = validRows.take(8).toList(growable: false);
  var importing = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(tr(context, 'product.list.importTitle')),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        context,
                        'product.list.importFile',
                        params: {'name': parseResult.fileLabel},
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        context,
                        'product.list.importSummary',
                        params: {
                          'total': '${parseResult.rows.length}',
                          'ready': '${parseResult.validCount}',
                          'errors': '${parseResult.errorCount}',
                        },
                      ),
                    ),
                    if (parseResult.errorCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        tr(context, 'product.list.importSkipErrors'),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              color: FlutterFlowTheme.of(context).error,
                            ),
                      ),
                    ],
                    if (previewRows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        tr(context, 'product.list.importPreview'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...previewRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${row.name} · ${row.sku} · '
                            '\$${row.price.toStringAsFixed(2)}'
                            '${row.category != null ? ' · ${row.category}' : ''}',
                          ),
                        ),
                      ),
                      if (validRows.length > previewRows.length)
                        Text(
                          tr(
                            context,
                            'product.list.importMore',
                            params: {
                              'count': '${validRows.length - previewRows.length}',
                            },
                          ),
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: importing
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(tr(context, 'common.cancel')),
              ),
              FFButtonWidget(
                onPressed: importing || validRows.isEmpty
                    ? null
                    : () async {
                        if (!ensureActiveCompanyForWrite(context)) {
                          return;
                        }
                        setDialogState(() => importing = true);
                        try {
                          final result =
                              await writeImportedProducts(parseResult.rows);
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);
                          final summary = StringBuffer()
                            ..write(
                              tr(
                                context,
                                'product.list.importCreated',
                                params: {'count': '${result.created}'},
                              ),
                            );
                          if (result.skippedDuplicates > 0) {
                            summary.write(
                              ' ${tr(context, 'product.list.importSkippedDuplicates', params: {'count': '${result.skippedDuplicates}'})}',
                            );
                          }
                          if (result.failed > 0) {
                            summary.write(
                              ' ${tr(context, 'product.list.importFailedCount', params: {'count': '${result.failed}'})}',
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(summary.toString())),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          setDialogState(() => importing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(
                                  context,
                                  'product.list.importFailed',
                                  params: {'error': '$error'},
                                ),
                              ),
                            ),
                          );
                        }
                      },
                text: importing
                    ? tr(context, 'product.list.importing')
                    : tr(context, 'product.list.importConfirm'),
                options: FFButtonOptions(
                  height: 40,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        color: Colors.white,
                      ),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> pickAndImportProducts(BuildContext context) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'xlsx'],
    withData: true,
    allowMultiple: false,
  );
  if (picked == null || picked.files.isEmpty) {
    return;
  }
  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'product.list.importReadFailed'))),
    );
    return;
  }

  try {
    final parsed = parseProductImportFile(
      bytes: bytes,
      filename: file.name,
    );
    if (!context.mounted) {
      return;
    }
    await showProductImportPreviewDialog(context, parsed);
  } on ProductImportException catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            'product.list.importFailed',
            params: {'error': '$error'},
          ),
        ),
      ),
    );
  }
}

class ProductImportButton extends StatelessWidget {
  const ProductImportButton({
    super.key,
    this.fullWidth = true,
  });

  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: () => pickAndImportProducts(context),
      text: tr(context, 'product.list.importButton'),
      icon: Icon(
        Icons.upload_file,
        size: 18,
        color: FlutterFlowTheme.of(context).primary,
      ),
      options: FFButtonOptions(
        width: fullWidth ? double.infinity : null,
        height: 44,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
        color: Colors.white,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              color: FlutterFlowTheme.of(context).primary,
              fontWeight: FontWeight.w500,
            ),
        elevation: 0,
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
