import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/company_profile_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/registration_approval_service.dart';
import '/backend/user_registration_request_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class ManageRegistrationRequestsPanel extends StatefulWidget {
  const ManageRegistrationRequestsPanel({super.key});

  @override
  State<ManageRegistrationRequestsPanel> createState() =>
      _ManageRegistrationRequestsPanelState();
}

class _ManageRegistrationRequestsPanelState
    extends State<ManageRegistrationRequestsPanel> {
  RegistrationRequestStatus? _statusFilter;
  String? _expandedId;
  bool _acting = false;

  String _statusLabel(BuildContext context, RegistrationRequestStatus status) {
    return tr(
      context,
      'admin.registrationRequests.status.${registrationRequestStatusKey(status)}',
    );
  }

  Color _statusColor(
    BuildContext context,
    RegistrationRequestStatus status,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return switch (status) {
      RegistrationRequestStatus.pending => theme.warning,
      RegistrationRequestStatus.approved => theme.success,
      RegistrationRequestStatus.rejected => theme.error,
    };
  }

  Future<void> _showPasswordResetLinkDialog(String link) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          tr(dialogContext, 'admin.registrationRequests.passwordResetLinkTitle'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(dialogContext, 'admin.registrationRequests.passwordResetLinkBody'),
            ),
            const SizedBox(height: 12),
            SelectableText(link),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr(context, 'admin.registrationRequests.linkCopied'),
                    ),
                  ),
                );
              }
            },
            child: Text(tr(dialogContext, 'admin.registrationRequests.copyLink')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(dialogContext, 'common.close')),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(UserRegistrationRequest request) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(dialogContext, 'admin.registrationRequests.rejectTitle')),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: tr(dialogContext, 'admin.registrationRequests.rejectNote'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, 'admin.registrationRequests.rejectConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }

    setState(() => _acting = true);
    final result = await rejectRegistrationRequest(
      requestId: request.id,
      note: noteController.text,
    );
    noteController.dispose();
    if (!mounted) {
      return;
    }
    setState(() => _acting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? tr(context, 'admin.registrationRequests.rejected')
              : result.errorMessage ??
                  tr(context, 'admin.registrationRequests.actionFailed'),
        ),
      ),
    );
  }

  Future<void> _approve(UserRegistrationRequest request) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(dialogContext, 'admin.registrationRequests.approveTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(dialogContext, 'admin.registrationRequests.approveBody')),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr(
                  dialogContext,
                  'admin.registrationRequests.initialPassword',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(dialogContext, 'admin.registrationRequests.approveServerNote'),
              style: FlutterFlowTheme.of(dialogContext).bodySmall.override(
                    color: FlutterFlowTheme.of(dialogContext).secondaryText,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, 'admin.registrationRequests.approveConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      passwordController.dispose();
      return;
    }

    setState(() => _acting = true);
    final result = await approveRegistrationRequest(
      requestId: request.id,
      initialPassword: passwordController.text,
    );
    passwordController.dispose();
    if (!mounted) {
      return;
    }
    setState(() => _acting = false);

    if (result.success) {
      if (result.passwordResetLink != null && result.passwordResetLink!.isNotEmpty) {
        await _showPasswordResetLinkDialog(result.passwordResetLink!);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'admin.registrationRequests.approved')),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.errorMessage ??
              tr(context, 'admin.registrationRequests.actionFailed'),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.labelMedium.override(color: theme.secondaryText),
            ),
          ),
          Expanded(child: Text(value, style: theme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    UserRegistrationRequest request,
    DateFormat dateFormat,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final expanded = _expandedId == request.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedId = expanded ? null : request.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.name,
                          style: theme.titleMedium.override(
                            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(request.email, style: theme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(context, request.status)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(context, request.status),
                      style: theme.labelSmall.override(
                        color: _statusColor(context, request.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.createdTime != null) ...[
                const SizedBox(height: 6),
                Text(
                  dateFormat.format(request.createdTime!),
                  style: theme.labelSmall,
                ),
              ],
              if (expanded) ...[
                const Divider(height: 24),
                _detailRow(
                  context,
                  tr(context, 'admin.registrationRequests.field.phone'),
                  request.phone,
                ),
                _detailRow(
                  context,
                  tr(context, 'admin.registrationRequests.field.accountType'),
                  tr(
                    context,
                    'admin.registrationRequests.accountType.${userSignupAccountTypeKey(request.accountType)}',
                  ),
                ),
                if (request.isCompanyAccount) ...[
                  _detailRow(
                    context,
                    tr(context, 'admin.registrationRequests.field.companyName'),
                    request.companyName,
                  ),
                  _detailRow(
                    context,
                    tr(context, 'admin.registrationRequests.field.companyUen'),
                    request.companyUen,
                  ),
                  _detailRow(
                    context,
                    tr(context, 'admin.registrationRequests.field.companyPhone'),
                    request.companyPhone,
                  ),
                  _detailRow(
                    context,
                    tr(context, 'admin.registrationRequests.field.companyEmail'),
                    request.companyEmail,
                  ),
                  _detailRow(
                    context,
                    tr(context, 'admin.registrationRequests.field.companyAddress'),
                    request.companyAddress,
                  ),
                  if (isUsableCompanyLogoUrl(request.companyLogoUrl))
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: buildCompanyLogoImage(
                        context: context,
                        logoUrl: request.companyLogoUrl,
                        companyId: request.id,
                        width: 96,
                        height: 96,
                      ),
                    ),
                ],
                if (request.rejectionNote != null &&
                    request.rejectionNote!.isNotEmpty)
                  _detailRow(
                    context,
                    tr(context, 'admin.registrationRequests.field.rejectionNote'),
                    request.rejectionNote,
                  ),
                if (request.isPending && !_acting) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () => _reject(request),
                          text: tr(
                            context,
                            'admin.registrationRequests.rejectButton',
                          ),
                          options: FFButtonOptions(
                            height: 44,
                            color: theme.error,
                            textStyle: theme.titleSmall.override(
                              color: Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () => _approve(request),
                          text: tr(
                            context,
                            'admin.registrationRequests.approveButton',
                          ),
                          options: FFButtonOptions(
                            height: 44,
                            color: theme.primary,
                            textStyle: theme.titleSmall.override(
                              color: Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'admin.registrationRequests.intro'),
          style: theme.bodyMedium.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(tr(context, 'admin.registrationRequests.filter.all')),
              selected: _statusFilter == null,
              onSelected: (_) => setState(() => _statusFilter = null),
            ),
            ChoiceChip(
              label: Text(
                tr(context, 'admin.registrationRequests.status.pending'),
              ),
              selected: _statusFilter == RegistrationRequestStatus.pending,
              onSelected: (_) => setState(
                () => _statusFilter = RegistrationRequestStatus.pending,
              ),
            ),
            ChoiceChip(
              label: Text(
                tr(context, 'admin.registrationRequests.status.approved'),
              ),
              selected: _statusFilter == RegistrationRequestStatus.approved,
              onSelected: (_) => setState(
                () => _statusFilter = RegistrationRequestStatus.approved,
              ),
            ),
            ChoiceChip(
              label: Text(
                tr(context, 'admin.registrationRequests.status.rejected'),
              ),
              selected: _statusFilter == RegistrationRequestStatus.rejected,
              onSelected: (_) => setState(
                () => _statusFilter = RegistrationRequestStatus.rejected,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_acting)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        Expanded(
          child: StreamBuilder<List<UserRegistrationRequest>>(
            stream: streamRegistrationRequests(statusFilter: _statusFilter),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(describeFirestoreError(snapshot.error!)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final requests = snapshot.data!;
              if (requests.isEmpty) {
                return Center(
                  child: Text(tr(context, 'admin.registrationRequests.empty')),
                );
              }
              return ListView(
                children: [
                  for (final request in requests)
                    _buildRequestCard(context, request, dateFormat),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
