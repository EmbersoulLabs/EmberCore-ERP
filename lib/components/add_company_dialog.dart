import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/manual_company_creation_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

Future<ManualCompanyCreationResult?> showAddCompanyDialog(
  BuildContext context,
) async {
  return showDialog<ManualCompanyCreationResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _AddCompanyDialog(),
  );
}

class _AddCompanyDialog extends StatefulWidget {
  const _AddCompanyDialog();

  @override
  State<_AddCompanyDialog> createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends State<_AddCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyUenController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _directorNameController = TextEditingController();
  final _directorEmailController = TextEditingController();
  final _directorPhoneController = TextEditingController();
  final _directorPasswordController = TextEditingController();

  bool _createDirector = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyUenController.dispose();
    _companyAddressController.dispose();
    _directorNameController.dispose();
    _directorEmailController.dispose();
    _directorPhoneController.dispose();
    _directorPasswordController.dispose();
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

    final result = await createCompanyManually(
      context: context,
      input: ManualCompanyCreationInput(
        companyName: _companyNameController.text,
        companyPhone: _companyPhoneController.text,
        companyAddress: _companyAddressController.text,
        companyUen: _companyUenController.text,
        createDirector: _createDirector,
        directorName: _directorNameController.text,
        directorEmail: _directorEmailController.text,
        directorPhone: _directorPhoneController.text,
        directorPassword: _directorPasswordController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.pop(context, result);
      return;
    }

    setState(() {
      _submitting = false;
      _errorMessage = result.errorMessage;
    });
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AlertDialog(
      title: Text(tr(context, 'admin.addCompany.title')),
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
                  tr(context, 'admin.addCompany.intro'),
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    context,
                    tr(context, 'admin.addCompany.companyName'),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return tr(context, 'admin.addCompany.companyNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration(
                    context,
                    tr(context, 'admin.addCompany.companyPhone'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyUenController,
                  decoration: _fieldDecoration(
                    context,
                    tr(context, 'admin.addCompany.companyUen'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyAddressController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _fieldDecoration(
                    context,
                    tr(context, 'admin.addCompany.companyAddress'),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr(context, 'admin.addCompany.createDirector'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    tr(context, 'admin.addCompany.createDirectorHint'),
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                    ),
                  ),
                  value: _createDirector,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _createDirector = value),
                ),
                if (_createDirector) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _directorNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(
                      context,
                      tr(context, 'admin.addCompany.directorName'),
                    ),
                    validator: (value) {
                      if (!_createDirector) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return tr(
                          context,
                          'admin.addCompany.directorNameRequired',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _directorEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration(
                      context,
                      tr(context, 'admin.addCompany.directorEmail'),
                    ),
                    validator: (value) {
                      if (!_createDirector) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return tr(
                          context,
                          'admin.addCompany.directorEmailRequired',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _directorPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDecoration(
                      context,
                      tr(context, 'admin.addCompany.directorPhone'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _directorPasswordController,
                    obscureText: true,
                    decoration: _fieldDecoration(
                      context,
                      tr(context, 'admin.addCompany.directorPassword'),
                    ),
                    validator: (value) {
                      if (!_createDirector) {
                        return null;
                      }
                      if (value == null || value.length < 6) {
                        return tr(
                          context,
                          'admin.addCompany.directorPasswordRequired',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'admin.addCompany.directorSessionWarning'),
                    style: theme.bodySmall.override(
                      color: theme.warning,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: theme.bodySmall.override(color: theme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(tr(context, 'common.cancel')),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr(context, 'admin.addCompany.submit')),
        ),
      ],
    );
  }
}
