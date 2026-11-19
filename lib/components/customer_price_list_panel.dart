import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/price_list_helpers.dart';
import '/backend/price_list_import_helpers.dart';
import '/components/price_list_import_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Credit-customer price list download / upload on the customer profile page.
class CustomerPriceListPanel extends StatefulWidget {
  const CustomerPriceListPanel({
    super.key,
    required this.customer,
    required this.onChanged,
  });

  final CustomersRecord customer;
  final Future<void> Function() onChanged;

  @override
  State<CustomerPriceListPanel> createState() => _CustomerPriceListPanelState();
}

class _CustomerPriceListPanelState extends State<CustomerPriceListPanel> {
  PriceListsRecord? _priceList;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _canManage =>
      canManageCreditAndInvoices(currentViewerRole());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CustomerPriceListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer.reference.path != widget.customer.reference.path ||
        oldWidget.customer.priceListRef?.path !=
            widget.customer.priceListRef?.path) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!widget.customer.hasPriceListRef()) {
        if (!mounted) {
          return;
        }
        setState(() {
          _priceList = null;
          _loading = false;
        });
        return;
      }
      final list = await PriceListsRecord.getDocumentOnce(
        widget.customer.priceListRef!,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _priceList = list;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = describeFirestoreError(error);
        _priceList = null;
      });
    }
  }

  Future<void> _downloadExisting() async {
    final list = _priceList;
    if (list == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'customer.profile.priceListNone'))),
      );
      return;
    }
    final lines = parsePriceListLines(list);
    final filename = priceListExportFilename(
      listName: priceListLabel(list),
      customerName: widget.customer.name,
    );
    await downloadFile(
      filename: filename,
      uploadedFile: FFUploadedFile(
        name: filename,
        bytes: priceListLinesToCsvBytes(lines),
      ),
    );
  }

  Future<void> _upload() async {
    if (!_canManage) {
      return;
    }
    final blocked = await TenantContext.instance.ensureReadyForTenantWrite();
    if (!mounted) {
      return;
    }
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }

    setState(() => _busy = true);
    try {
      final hadList = widget.customer.hasPriceListRef();
      final priceListRef = await ensureCustomerAssignedPriceList(
        widget.customer,
      );
      if (!hadList) {
        await widget.onChanged();
      }
      if (!mounted) {
        return;
      }
      await pickAndImportPriceListFile(
        context,
        priceListRef: priceListRef,
        onImported: () async {
          await widget.onChanged();
          await _load();
        },
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeFirestoreError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final list = _priceList;
    final lineCount = list == null ? 0 : parsePriceListLines(list).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(context, 'customer.profile.priceListTitle'),
              style: theme.titleMedium.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(context, 'customer.profile.priceListHint'),
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_error != null)
              Text(
                _error!,
                style: theme.bodyMedium.override(color: theme.error),
              )
            else ...[
              Text(
                list == null
                    ? tr(context, 'customer.profile.priceListNone')
                    : tr(
                        context,
                        'customer.profile.priceListBound',
                        params: {
                          'name': priceListLabel(list),
                          'count': '$lineCount',
                        },
                      ),
                style: theme.bodyMedium.override(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy || list == null ? null : _downloadExisting,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(tr(context, 'customer.profile.priceListDownload')),
                  ),
                  if (_canManage)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _upload,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(tr(context, 'customer.profile.priceListUpload')),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
