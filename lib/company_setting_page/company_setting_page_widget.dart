import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/role_helpers.dart';
import '/backend/branch_helpers.dart';
import '/backend/company_profile_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/add_branch_dialog.dart';
import '/components/company_logo_editor.dart';
import '/components/ember_app_shell.dart';
import '/components/ember_form_field.dart';
import '/components/ember_section_card.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_navigation.dart';
import 'company_setting_page_model.dart';
export 'company_setting_page_model.dart';

class CompanySettingPageWidget extends StatefulWidget {
  const CompanySettingPageWidget({super.key});

  static String routeName = 'CompanySettingPage';
  static String routePath = '/companySettingPage';

  @override
  State<CompanySettingPageWidget> createState() =>
      _CompanySettingPageWidgetState();
}

class _CompanySettingPageWidgetState extends State<CompanySettingPageWidget> {
  late CompanySettingPageModel _model;

  DocumentReference? _companyRef;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;
  String _logoUrl = '';
  String? _loadError;
  CompaniesRecord? _loadedCompany;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CompanySettingPageModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.textController1Validator = (context, val) {
      if (val == null || val.trim().isEmpty) {
        return tr(context, 'settings.company.nameRequired');
      }
      return null;
    };

    _model.switchValue = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePage());
  }

  Future<void> _initializePage() async {
    if (!canEditCompanyProfile(AppStateNotifier.instance.userRole)) {
      if (!mounted) {
        return;
      }
      safeSetState(() {
        _loading = false;
        _loadError = tr(context, 'settings.company.noPermission');
      });
      return;
    }

    final profile = await resolveCurrentUserProfile();
    final companyRef = resolveCompanyRefForProfileEdit(profile);
    if (companyRef == null) {
      if (!mounted) {
        return;
      }
      safeSetState(() {
        _loading = false;
        _loadError = TenantContext.instance.isViewingAllCompanies
            ? tr(context, 'settings.company.selectCompanyFirst')
            : tr(context, 'settings.company.noCompanyLinked');
      });
      return;
    }

    try {
      final company = await loadCompanyProfile(companyRef);
      if (!mounted) {
        return;
      }
      _populateForm(company, companyRef);
      safeSetState(() {
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      safeSetState(() {
        _loading = false;
        _loadError = tr(context, 'settings.company.loadFailed');
      });
    }
  }

  void _populateForm(CompaniesRecord company, DocumentReference companyRef) {
    _companyRef = companyRef;
    _loadedCompany = company;
    _logoUrl = company.logo;
    _model.textController1!.text = company.companyName;
    _model.textController2!.text = company.companyUen;
    _model.textController3!.text = company.companyPhone;
    _model.textController4!.text = company.companyAddress;
    _model.switchValue = company.isActive;
  }

  Future<void> _pickLogo() async {
    final companyRef = _companyRef;
    if (companyRef == null) {
      return;
    }
    safeSetState(() => _uploadingLogo = true);
    try {
      final url = await pickAndUploadCompanyLogo(
        context: context,
        companyRef: companyRef,
      );
      if (url != null) {
        safeSetState(() => _logoUrl = url);
      }
    } finally {
      safeSetState(() => _uploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    final companyRef = _companyRef;
    if (companyRef == null) {
      return;
    }
    safeSetState(() => _uploadingLogo = true);
    try {
      await companyRef.update(createCompaniesRecordData(logo: ''));
      if (TenantContext.instance.activeCompanyRef?.path == companyRef.path) {
        await TenantContext.instance.reloadActiveCompany();
      }
      safeSetState(() => _logoUrl = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'settings.company.logoRemoved')),
          ),
        );
      }
    } finally {
      safeSetState(() => _uploadingLogo = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_companyRef == null || _saving) {
      return;
    }
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }

    safeSetState(() => _saving = true);
    try {
      await saveCompanyProfile(
        companyRef: _companyRef!,
        companyName: _model.textController1!.text.trim(),
        companyUen: _model.textController2!.text.trim(),
        companyPhone: _model.textController3!.text.trim(),
        companyAddress: _model.textController4!.text.trim(),
        logoUrl: _logoUrl,
        isActive: isSuperAdminRole(AppStateNotifier.instance.userRole)
            ? _model.switchValue
            : null,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'settings.company.saveSuccess'))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'settings.company.saveFailed'))),
      );
    } finally {
      safeSetState(() => _saving = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String labelKey,
    required String hintKey,
    String? Function(BuildContext, String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      style: emberFormFieldTextStyle(context),
      decoration: emberFormInputDecoration(
        context,
        labelText: tr(context, labelKey),
        hintText: tr(context, hintKey),
      ),
      validator: validator?.asValidator(context),
    );
  }

  Future<void> _openAddBranchDialog() async {
    final hq = _loadedCompany;
    if (hq == null) {
      return;
    }
    final result = await showAddBranchDialog(context, headquarters: hq);
    if (!mounted || result == null) {
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'branch.create.success'))),
      );
      safeSetState(() {});
    }
  }

  Widget _buildBranchesSection() {
    final hq = _loadedCompany;
    if (hq == null) {
      return const SizedBox.shrink();
    }
    final role = AppStateNotifier.instance.userRole;
    if (!canManageOrgBranches(role: role, activeCompany: hq)) {
      return const SizedBox.shrink();
    }
    final orgId = orgIdForCompany(hq);
    final theme = FlutterFlowTheme.of(context);
    final planBlock = branchPlanBlockMessage(hq);

    return EmberSectionCard(
      title: tr(context, 'branch.section.title'),
      trailing: planBlock == null
          ? TextButton.icon(
              onPressed: _openAddBranchDialog,
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: Text(tr(context, 'branch.create.submit')),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (planBlock != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tr(context, planBlock),
                style: theme.bodyMedium.override(color: theme.error),
              ),
            ),
          StreamBuilder<QuerySnapshot>(
            stream: branchesQueryForOrg(orgId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                );
              }
              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return Text(tr(context, 'branch.section.empty'));
              }
              return Column(
                children: docs.map((doc) {
                  final branch = CompaniesRecord.fromSnapshot(doc);
                  final subtitle = [
                    if (branch.branchCode.isNotEmpty) branch.branchCode,
                    if (branch.companyAddress.isNotEmpty)
                      branch.companyAddress,
                  ].join(' · ');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.store_outlined),
                    title: Text(branch.companyName),
                    subtitle:
                        subtitle.isEmpty ? null : Text(subtitle),
                    trailing: IconButton(
                      tooltip: tr(context, 'branch.action.switch'),
                      icon: const Icon(Icons.login_outlined),
                      onPressed: () async {
                        await TenantContext.instance.setActiveCompany(
                          branch.reference,
                          viewAll: isSuperAdminRole(role),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(
                                  context,
                                  'branch.action.switched',
                                  params: {'name': branch.companyName},
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody() {
    final isSuperAdmin =
        isSuperAdminRole(AppStateNotifier.instance.userRole);
    final theme = FlutterFlowTheme.of(context);

    return Form(
      key: _model.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmberSectionCard(
            title: tr(context, 'settings.company.section.branding'),
            child: CompanyLogoEditor(
              logoUrl: _logoUrl,
              companyId: _companyRef?.id,
              uploading: _uploadingLogo,
              onPickLogo: _pickLogo,
              onRemoveLogo: _removeLogo,
            ),
          ),
          const SizedBox(height: 16),
          EmberSectionCard(
            title: tr(context, 'settings.company.section.details'),
            child: Column(
              children: [
                _buildTextField(
                  controller: _model.textController1,
                  focusNode: _model.textFieldFocusNode1,
                  labelKey: 'settings.company.name',
                  hintKey: 'settings.company.nameHint',
                  validator: _model.textController1Validator,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _model.textController2,
                  focusNode: _model.textFieldFocusNode2,
                  labelKey: 'settings.company.uen',
                  hintKey: 'settings.company.uenHint',
                  validator: _model.textController2Validator,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _model.textController3,
                  focusNode: _model.textFieldFocusNode3,
                  labelKey: 'settings.company.phone',
                  hintKey: 'settings.company.phoneHint',
                  validator: _model.textController3Validator,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _model.textController4,
                  focusNode: _model.textFieldFocusNode4,
                  labelKey: 'settings.company.address',
                  hintKey: 'settings.company.addressHint',
                  validator: _model.textController4Validator,
                  minLines: 3,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          if (isSuperAdmin) ...[
            const SizedBox(height: 16),
            EmberSectionCard(
              title: tr(context, 'settings.company.section.status'),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr(context, 'settings.company.activeStatus')),
                subtitle: Text(
                  tr(context, 'settings.company.activeStatusHint'),
                  style: theme.bodySmall.override(
                    color: EmberBrand.textSecondary,
                  ),
                ),
                value: _model.switchValue ?? true,
                activeThumbColor: EmberBrand.electricBlue,
                onChanged: (value) =>
                    safeSetState(() => _model.switchValue = value),
              ),
            ),
          ],
          if (_loadedCompany != null &&
              _loadedCompany!.companyKind != 'branch') ...[
            const SizedBox(height: 16),
            _buildBranchesSection(),
          ],
          const SizedBox(height: 24),
          if (canViewUserList(AppStateNotifier.instance.userRole)) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  context.pushNamed(UserListPageWidget.routeName),
              style: emberSecondaryButtonStyle(context),
              icon: const Icon(Icons.people_outline),
              label: Text(tr(context, 'settings.company.viewUserList')),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _saving ? null : _saveChanges,
            style: emberPrimaryButtonStyle(context),
            child: Text(
              _saving
                  ? tr(context, 'common.saving')
                  : tr(context, 'settings.company.save'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: EmberAppShell(
        selectedPath: CompanySettingPageWidget.routePath,
        title: tr(context, 'settings.businessProfile'),
        subtitle: tr(context, 'settings.businessProfile.subtitle'),
        showBackButton: true,
        navGroups: buildEmberNavGroups(context),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyLarge,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth > 900
                            ? 720.0
                            : double.infinity;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              child: _buildFormBody(),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
