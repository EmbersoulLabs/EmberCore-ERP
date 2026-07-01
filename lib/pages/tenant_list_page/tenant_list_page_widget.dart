import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/company_query_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/tenant_admin_service.dart';
import '/backend/tenant_context.dart';
import '/components/ember_app_bar.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'tenant_list_page_model.dart';
export 'tenant_list_page_model.dart';

class TenantListPageWidget extends StatefulWidget {
  const TenantListPageWidget({super.key});

  static String routeName = 'TenantListPage';
  static String routePath = '/tenantList';

  @override
  State<TenantListPageWidget> createState() => _TenantListPageWidgetState();
}

class _TenantListPageWidgetState extends State<TenantListPageWidget> {
  late TenantListPageModel _model;
  String? _actingCompanyId;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TenantListPageModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _toggleActive(TenantAdminSummary summary, bool nextActive) async {
    if (!nextActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(dialogContext, 'admin.tenants.deactivateTitle')),
          content: Text(tr(dialogContext, 'admin.tenants.deactivateBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(dialogContext, 'common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr(dialogContext, 'admin.tenants.deactivateConfirm')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _actingCompanyId = summary.company.reference.id);
    final result = await setTenantCompanyActive(
      companyRef: summary.company.reference,
      isActive: nextActive,
    );
    if (!mounted) {
      return;
    }
    setState(() => _actingCompanyId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? tr(
                  context,
                  nextActive
                      ? 'admin.tenants.activated'
                      : 'admin.tenants.deactivated',
                )
              : result.errorMessage ??
                  tr(context, 'admin.registrationRequests.actionFailed'),
        ),
      ),
    );
  }

  String _formatCreatedAt(DateTime? createdAt) {
    if (createdAt == null) {
      return '—';
    }
    return dateTimeFormat(
      'd/M/y',
      createdAt,
      locale: FFLocalizations.of(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSuperAdmin = isSuperAdminRole(currentViewerRole());

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: EmberPrimaryAppBar(
        title: tr(context, 'admin.tenants.title'),
        onBack: () => context.pop(),
        backgroundColor: theme.primary,
        actions: const [HomeNavIconButton.onPrimary()],
      ),
      body: !isSuperAdmin
          ? Center(child: Text(tr(context, 'admin.tenants.noAccess')))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr(context, 'admin.tenants.intro'),
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _model.searchController,
                      focusNode: _model.searchFocusNode,
                      decoration: InputDecoration(
                        hintText: tr(context, 'admin.tenants.searchHint'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.secondaryBackground,
                      ),
                      onChanged: (_) => safeSetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<TenantAdminSummary>>(
                        stream: streamTenantAdminSummaries(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                describeFirestoreError(snapshot.error!),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.primary,
                                ),
                              ),
                            );
                          }

                          final search = _model.searchController?.text ?? '';
                          final summaries = filterCompaniesBySearchQuery(
                            snapshot.data!.map((s) => s.company).toList(),
                            search,
                          ).map((company) {
                            return snapshot.data!.firstWhere(
                              (s) => s.company.reference.id == company.reference.id,
                            );
                          }).toList();

                          if (summaries.isEmpty) {
                            return Center(
                              child: Text(tr(context, 'admin.tenants.empty')),
                            );
                          }

                          return ListView.separated(
                            itemCount: summaries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final summary = summaries[index];
                              final company = summary.company;
                              final busy =
                                  _actingCompanyId == company.reference.id;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              company.companyName,
                                              style: theme.titleMedium.override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Switch(
                                            value: company.isActive,
                                            onChanged: busy
                                                ? null
                                                : (value) =>
                                                    _toggleActive(summary, value),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 6,
                                        children: [
                                          _metaChip(
                                            context,
                                            tr(
                                              context,
                                              'admin.tenants.staffCount',
                                            ).replaceAll(
                                              '{count}',
                                              '${summary.staffCount}',
                                            ),
                                          ),
                                          _metaChip(
                                            context,
                                            tr(
                                              context,
                                              'admin.tenants.created',
                                            ).replaceAll(
                                              '{date}',
                                              _formatCreatedAt(company.createdAt),
                                            ),
                                          ),
                                          if (company.subscriptionStatus.isNotEmpty)
                                            _metaChip(
                                              context,
                                              company.subscriptionStatus,
                                            ),
                                        ],
                                      ),
                                      if (!company.isActive) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          tr(context, 'admin.tenants.inactiveHint'),
                                          style: theme.bodySmall.override(
                                            color: theme.error,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () async {
                                              await TenantContext.instance
                                                  .setActiveCompany(
                                                company.reference,
                                                viewAll: false,
                                              );
                                              if (!context.mounted) {
                                                return;
                                              }
                                              context.pushNamed(
                                                IndustrySettingsPageWidget.routeName,
                                              );
                                            },
                                            icon: const Icon(Icons.tune, size: 18),
                                            label: Text(
                                              tr(
                                                context,
                                                'dashboard.action.industrySettings',
                                              ),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () async {
                                              await TenantContext.instance
                                                  .setActiveCompany(
                                                company.reference,
                                                viewAll: false,
                                              );
                                              if (!context.mounted) {
                                                return;
                                              }
                                              context.go(
                                                SalesDashBoardWidget.routePath,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              size: 18,
                                            ),
                                            label: Text(
                                              tr(context, 'admin.tenants.openTenant'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _metaChip(BuildContext context, String label) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.alternate.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.bodySmall,
      ),
    );
  }
}
