import 'package:flutter/material.dart';

import '/backend/branch_creation_service.dart';
import '/backend/branch_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/components/ember_form_field.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

Future<BranchCreationResult?> showAddBranchDialog(
  BuildContext context, {
  required CompaniesRecord headquarters,
}) async {
  return showDialog<BranchCreationResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _AddBranchDialog(headquarters: headquarters),
  );
}

class _AddBranchDialog extends StatefulWidget {
  const _AddBranchDialog({required this.headquarters});

  final CompaniesRecord headquarters;

  @override
  State<_AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends State<_AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _uenController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _uenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await createBranchViaCallable(
      BranchCreationInput(
        headquartersCompanyId: widget.headquarters.reference.id,
        branchName: _nameController.text,
        branchPhone: _phoneController.text,
        branchAddress: _addressController.text,
        branchUen: _uenController.text,
        branchCode: _codeController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.of(context).pop(result);
      return;
    }

    setState(() {
      _submitting = false;
      _errorMessage = result.errorMessage ?? tr(context, 'branch.create.failed');
    });
  }

  InputDecoration _decoration(String labelKey, {String? hintKey}) {
    return emberFormInputDecoration(
      context,
      labelText: tr(context, labelKey),
      hintText: hintKey != null ? tr(context, hintKey) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final planBlock = branchPlanBlockMessage(widget.headquarters);

    return AlertDialog(
      title: Text(tr(context, 'branch.create.title')),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(
                    context,
                    'branch.create.subtitle',
                    params: {'hq': widget.headquarters.companyName},
                  ),
                  style: theme.bodyMedium.override(
                    color: EmberBrand.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (planBlock != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.error),
                    ),
                    child: Text(
                      tr(context, planBlock),
                      style: theme.bodyMedium.override(color: theme.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: theme.bodyMedium.override(color: theme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: emberFormFieldTextStyle(context),
                  decoration: _decoration(
                    'branch.form.name',
                    hintKey: 'branch.form.nameHint',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return tr(context, 'branch.form.nameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  style: emberFormFieldTextStyle(context),
                  decoration: _decoration(
                    'branch.form.code',
                    hintKey: 'branch.form.codeHint',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: emberFormFieldTextStyle(context),
                  decoration: _decoration(
                    'branch.form.phone',
                    hintKey: 'settings.company.phoneHint',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  minLines: 2,
                  maxLines: 3,
                  style: emberFormFieldTextStyle(context),
                  decoration: _decoration(
                    'branch.form.address',
                    hintKey: 'settings.company.addressHint',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _uenController,
                  style: emberFormFieldTextStyle(context),
                  decoration: _decoration(
                    'branch.form.uen',
                    hintKey: 'settings.company.uenHint',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(tr(context, 'common.cancel')),
        ),
        FilledButton(
          onPressed: (_submitting || planBlock != null) ? null : _submit,
          style: emberPrimaryButtonStyle(context),
          child: Text(
            _submitting
                ? tr(context, 'common.saving')
                : tr(context, 'branch.create.submit'),
          ),
        ),
      ],
    );
  }
}
