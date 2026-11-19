import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_ready_by_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/l10n/tr.dart';

Future<void> showAssignReadyBySheet(
  BuildContext context, {
  required OrdersRecord order,
  List<UsersRecord>? staff,
}) async {
  if (!canAssignReadyBy(AppStateNotifier.instance.userRole)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'order.readyBy.denied'))),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AssignReadyBySheet(
      order: order,
      staff: staff,
    ),
  );
}

class _AssignReadyBySheet extends StatefulWidget {
  const _AssignReadyBySheet({
    required this.order,
    this.staff,
  });

  final OrdersRecord order;
  final List<UsersRecord>? staff;

  @override
  State<_AssignReadyBySheet> createState() => _AssignReadyBySheetState();
}

class _AssignReadyBySheetState extends State<_AssignReadyBySheet> {
  bool _saving = false;
  bool _loading = false;
  DocumentReference? _selectedRef;
  List<UsersRecord> _staff = const [];

  @override
  void initState() {
    super.initState();
    _selectedRef = widget.order.readyBy;
    final passed = widget.staff;
    if (passed != null) {
      _staff = passed;
    } else {
      _loading = true;
      _loadStaff();
    }
  }

  Future<void> _loadStaff() async {
    final all = await queryUsersRecordOnce();
    if (!mounted) {
      return;
    }
    setState(() {
      _staff = all;
      _loading = false;
    });
  }

  List<UsersRecord> get _options => readyByAssignableStaff(
        _staff,
        companyId: TenantContext.instance.writeCompanyId,
        includeRef: widget.order.readyBy,
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await saveOrderReadyBy(
        orderRef: widget.order.reference,
        staffRef: _selectedRef,
      );
      await auditLogAssignReadyBy(
        order: widget.order,
        oldStaffId: widget.order.readyBy?.id,
        newStaffId: _selectedRef?.id,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.readyBy.saved'))),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'order.readyBy.failed', params: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final options = _options;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'order.readyBy.title'),
                style: theme.titleLarge.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr(context, 'order.readyBy.hint'),
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (options.isEmpty)
                Text(
                  tr(context, 'order.readyBy.empty'),
                  style: theme.bodyMedium,
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      RadioListTile<DocumentReference?>(
                        value: null,
                        groupValue: _selectedRef,
                        onChanged: _saving
                            ? null
                            : (ref) => setState(() => _selectedRef = ref),
                        title: Text(tr(context, 'order.readyBy.unassigned')),
                      ),
                      for (final user in options)
                        RadioListTile<DocumentReference?>(
                          value: user.reference,
                          groupValue: _selectedRef,
                          onChanged: _saving
                              ? null
                              : (ref) => setState(() => _selectedRef = ref),
                          title: Text(readyByDisplayName(user)),
                          subtitle: user.email.trim().isNotEmpty
                              ? Text(user.email)
                              : null,
                          secondary: CircleAvatar(
                            radius: 10,
                            backgroundColor: readyByStaffColor(
                              readyByStaffKey(user),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving || _loading ? null : _save,
                child: Text(
                  _saving
                      ? tr(context, 'common.saving')
                      : tr(context, 'common.save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
