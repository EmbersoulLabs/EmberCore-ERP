import '/app_version.dart';
import '/auth/role_helpers.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/create_order_service.dart';
import '/backend/dashboard_order_stats_helpers.dart';
import '/components/ember_app_bar.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/backend/whatsapp_order_import_service.dart';
import '/platform/platform_labels.dart';
import '/platform/platform_module.dart';
import '/components/ember_app_shell.dart';
import '/components/ember_dashboard_sections.dart';
import '/components/ember_metric_card.dart';
import '/components/whatsapp_order_paste_button.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_navigation.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sales_dash_board_model.dart';
export 'sales_dash_board_model.dart';

/// Create a FlutterFlow Page named "SalesDashboard" for an internal POS and
/// order management system.
///
/// Layout:
/// - AppBar with title "Sales Dashboard"
/// - Vertical scroll layout
/// - Clean admin-style UI
///
/// Dashboard Cards:
/// 1) Today Orders
///    - Count orders created today
///    - Firestore: orders
///    - Filter by created_time = today
///
/// 2) Pending Orders
///    - Count orders where status = "Pending"
///
/// 3) Completed Orders
///    - Count orders where status = "Completed"
///
/// Sales Summary:
/// - Today Sales Total
///   - Sum orders.total for today
/// - This Month Sales Total
///   - Sum orders.total for current month
///
/// Actions:
/// - Primary button: "+ Create Order"
///   - On tap, show Bottom Sheet:
///     - POS / Cashier Order
///     - Delivery Order
///   - Navigate to ProductSelectionPage
///   - Pass parameter: orderType
///
/// Navigation:
/// - Button: "All Orders"
///   - Navigate to OrderListPage
///
/// Requirements:
/// - Use Firebase Firestore
/// - Use FlutterFlow native widgets and actions
/// - Mobile-first responsive layout
class SalesDashBoardWidget extends StatefulWidget {
  const SalesDashBoardWidget({
    super.key,
    this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'SalesDashBoard';
  static String routePath = '/salesDashBoard';

  @override
  State<SalesDashBoardWidget> createState() => _SalesDashBoardWidgetState();
}

class _SalesDashBoardWidgetState extends State<SalesDashBoardWidget> {
  late SalesDashBoardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _creatingOrder = false;
  Future<DashboardOrderStatsLoadResult>? _statsFuture;
  int _statsGeneration = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SalesDashBoardModel());
    DashboardStatsRefresh.instance.addListener(_onDashboardStatsRefreshRequested);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        _reloadDashboardStats(rollForward: true);
      }
    });
  }

  @override
  void dispose() {
    DashboardStatsRefresh.instance.removeListener(_onDashboardStatsRefreshRequested);
    _model.dispose();

    super.dispose();
  }

  void _onDashboardStatsRefreshRequested() {
    if (!mounted) {
      return;
    }
    _reloadDashboardStats(rollForward: false);
  }

  Future<void> _openFilteredOrdersAndRefresh(
    DashboardOrderListFilter filter,
  ) async {
    await openDashboardFilteredOrderList(context, filter);
    if (mounted) {
      _reloadDashboardStats(rollForward: false);
    }
  }

  void _reloadDashboardStats({required bool rollForward}) {
    final future = rollForward
        ? loadDashboardOrderStatsWithRollForward()
        : loadDashboardOrderStatsFresh();

    setState(() {
      _statsGeneration++;
      _statsFuture = future;
    });

    if (!rollForward) {
      return;
    }

    future.then((result) {
      if (mounted && result.rolledForwardCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'dashboard.leftoverMoved',
                  params: {'count': '${result.rolledForwardCount}'}),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: EmberAppShell(
        selectedPath: SalesDashBoardWidget.routePath,
        title: tr(context, 'dashboard.title'),
        subtitle: tr(context, 'dashboard.subtitle'),
        onMenuPressed: () => _showDashboardMenuSheet(context),
        navGroups: buildEmberNavGroups(
          context,
          onCreateOrder: _creatingOrder ? null : () => _createOrder(context),
          onOrderImport: () => runWhatsAppOrderImportFromDashboard(context),
        ),
        extraActions: [
          ListenableBuilder(
            listenable: TenantContext.instance,
            builder: (context, _) {
              if (!isSuperAdminRole(AppStateNotifier.instance.userRole)) {
                return const SizedBox.shrink();
              }
              final scopeLabel = TenantContext.instance.viewScopeLabel;
              final icon = TenantContext.instance.isViewingAllCompanies
                  ? Icons.business
                  : Icons.filter_alt;
              if (emberCompactAppBar(context)) {
                return EmberAppBarIconButton(
                  icon: icon,
                  tooltip: scopeLabel,
                  onPrimary: true,
                  onPressed: () {
                    context.pushNamed(CompanySelectionPageWidget.routeName);
                  },
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  onPressed: () {
                    context.pushNamed(CompanySelectionPageWidget.routeName);
                  },
                  icon: Icon(icon, size: 18, color: Colors.white),
                  label: Text(
                    scopeLabel,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ],
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final statColumns = wide ? 3 : 2;
              final statAspectRatio = wide ? 1.65 : 1.35;

              return RefreshIndicator(
                onRefresh: () async {
                  _reloadDashboardStats(rollForward: false);
                  await _statsFuture;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 16,
                    wide ? 24 : 12,
                    wide ? 28 : 16,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!wide)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            appVersionDisplay,
                            style: theme.labelSmall.override(
                              color: EmberBrand.textSecondary,
                            ),
                          ),
                        ),
                      FutureBuilder<DashboardOrderStatsLoadResult>(
                        key: ValueKey(_statsGeneration),
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                describeFirestoreError(snapshot.error!),
                                textAlign: TextAlign.center,
                                style: theme.bodyMedium.override(
                                  color: theme.error,
                                ),
                              ),
                            );
                          }
                          final stats = snapshot.data?.stats;
                          final loading = !snapshot.hasData &&
                              snapshot.connectionState ==
                                  ConnectionState.waiting;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GridView.count(
                                crossAxisCount: statColumns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: statAspectRatio,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  EmberMetricCard(
                                    icon: Icons.receipt_long_outlined,
                                    accentColor: EmberBrand.electricBlue,
                                    label: tr(
                                      context,
                                      'dashboard.stat.todayDelivery',
                                    ),
                                    loading: loading,
                                    value: Text(
                                      _countText(stats?.todayTotalOrders),
                                    ),
                                    onTap: () => _openFilteredOrdersAndRefresh(
                                      DashboardOrderListFilter.todayTotalOrders,
                                    ),
                                  ),
                                  EmberMetricCard(
                                    icon: Icons.pending_actions_outlined,
                                    accentColor: EmberBrand.electricBlue,
                                    label: tr(
                                      context,
                                      'dashboard.stat.todayPending',
                                    ),
                                    loading: loading,
                                    value: Text(
                                      _countText(stats?.todayPendingOrders),
                                    ),
                                    onTap: () => _openFilteredOrdersAndRefresh(
                                      DashboardOrderListFilter
                                          .todayPendingOrders,
                                    ),
                                  ),
                                  EmberMetricCard(
                                    icon: Icons.inventory_2_outlined,
                                    accentColor: EmberBrand.teal,
                                    label: tr(
                                      context,
                                      'dashboard.stat.readyForDelivery',
                                    ),
                                    loading: loading,
                                    value: Text(
                                      _countText(stats?.readyForDelivery),
                                    ),
                                    onTap: () => _openFilteredOrdersAndRefresh(
                                      DashboardOrderListFilter
                                          .todayReadyForDelivery,
                                    ),
                                  ),
                                  EmberMetricCard(
                                    icon: Icons.check_circle_outline,
                                    accentColor: EmberBrand.teal,
                                    label: tr(
                                      context,
                                      'dashboard.stat.todayComplete',
                                    ),
                                    loading: loading,
                                    value: Text(
                                      _countText(stats?.todayCompletedOrders),
                                    ),
                                    onTap: () => _openFilteredOrdersAndRefresh(
                                      DashboardOrderListFilter
                                          .todayCompletedOrders,
                                    ),
                                  ),
                                  EmberMetricCard(
                                    icon: Icons.payments_outlined,
                                    accentColor: EmberBrand.amber,
                                    highlight: true,
                                    label: tr(
                                      context,
                                      'dashboard.stat.todayTotal',
                                    ),
                                    loading: loading,
                                    value: Text(
                                      EmberBrand.formatMoney(
                                        stats?.todayRevenue ?? 0,
                                      ),
                                    ),
                                    onTap: () => _openFilteredOrdersAndRefresh(
                                      DashboardOrderListFilter.todayTotalOrders,
                                    ),
                                  ),
                                  EmberMetricCard(
                                    icon: Icons.warning_amber_rounded,
                                    accentColor: EmberBrand.amber,
                                    label: tr(
                                      context,
                                      'dashboard.stat.unpaidOrders',
                                    ),
                                    loading: loading,
                                    value: Text(
                                      _countText(stats?.unpaidOrders),
                                    ),
                                    onTap: () => _openFilteredOrdersAndRefresh(
                                      DashboardOrderListFilter.todayUnpaidOrders,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (stats != null) ...[
                                EmberOrderFlowPipeline(
                                  pipeline: stats.pipeline,
                                ),
                                const SizedBox(height: 20),
                                EmberActionRequiredCard(
                                  actionRequired: stats.actionRequired,
                                  onItemTap: (_) => _openFilteredOrdersAndRefresh(
                                    DashboardOrderListFilter.todayTotalOrders,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        tr(context, 'dashboard.quickActions'),
                        style: theme.titleLarge.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.bold,
                            color: EmberBrand.navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FFButtonWidget(
                        onPressed: _creatingOrder
                            ? null
                            : () => _createOrder(context),
                        text: _creatingOrder
                            ? tr(context, 'dashboard.creating')
                            : tr(context, 'dashboard.createOrder'),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 52.0,
                          color: EmberBrand.navy,
                          textStyle: theme.titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(
                            EmberBrand.radiusLg,
                          ),
                          elevation: 0,
                        ),
                      ),
                      if (isWhatsAppOrderImportEnabled &&
                          platformModuleEnabled(
                            PlatformModule.whatsappImport,
                          )) ...[
                        const SizedBox(height: 10),
                        WhatsAppOrderPasteButton(
                          fullWidth: true,
                          label: tr(context, 'dashboard.orderImport'),
                          onDashboardImport: () =>
                              runWhatsAppOrderImportFromDashboard(context),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _createOrder(BuildContext context) async {
    setState(() => _creatingOrder = true);
    try {
      await createDraftOrderAndOpenProductSelection(context);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final theme = FlutterFlowTheme.of(context);
      final message = describeFirestoreError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.error,
          duration: const Duration(seconds: 8),
        ),
      );
      if (isSuperAdminRole(AppStateNotifier.instance.userRole) &&
          (message.contains('company') ||
              message.contains('Company') ||
              message.contains('users/'))) {
        context.pushNamed(CompanySelectionPageWidget.routeName);
      }
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  String _countText(int? count) =>
      count == null ? '--' : count.toString();

  List<_DashboardMenuSection> _dashboardMenuSections(BuildContext context) {
    final role = AppStateNotifier.instance.userRole;

    _DashboardMenuAction action({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return _DashboardMenuAction(
        label: label,
        icon: icon,
        onPressed: onPressed,
      );
    }

    final sections = <_DashboardMenuSection>[
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.orders'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.allOrders'),
            icon: Icons.list_alt,
            onPressed: () async {
              await context.pushNamed(OrderlistWidget.routeName);
              if (mounted) {
                _reloadDashboardStats(rollForward: false);
              }
            },
          ),
          if (canAssignDriver(role))
            action(
              label: tr(context, 'dashboard.action.driverAssignments'),
              icon: Icons.local_shipping_outlined,
              onPressed: () =>
                  context.pushNamed(DriverAssignmentsPageWidget.routeName),
            ),
          if (canViewDeletedOrders(role))
            action(
              label: tr(context, 'dashboard.action.deletedOrders'),
              icon: Icons.delete_sweep_outlined,
              onPressed: () =>
                  context.pushNamed(DeletedOrdersPageWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.customersBilling'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.customers'),
            icon: Icons.people_outline,
            onPressed: () =>
                context.pushNamed(CustomerListPageWidget.routeName),
          ),
          if (canViewCreditAndInvoices(role))
            action(
              label: tr(context, 'dashboard.action.invoiceList'),
              icon: Icons.receipt_long_outlined,
              onPressed: () =>
                  context.pushNamed(InvoiceListPageWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.catalog'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.productList'),
            icon: Icons.inventory_2_outlined,
            onPressed: () => context.pushNamed(ProductlistWidget.routeName),
          ),
          if ((canCreateProducts(role) || canEditProducts(role)) &&
              platformModuleEnabled(PlatformModule.materialsBom))
            action(
              label: tr(context, 'dashboard.action.materialList'),
              icon: Icons.grass_outlined,
              onPressed: () => context.pushNamed(MateriallistWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.reports'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.salesReport'),
            icon: Icons.assessment,
            onPressed: () =>
                context.pushNamed(SalesReportPageWidget.routeName),
          ),
          if ((canCreateProducts(role) || canEditProducts(role)) &&
              platformModuleEnabled(PlatformModule.materialsBom))
            action(
              label: tr(context, 'dashboard.action.materialUsage'),
              icon: Icons.inventory_outlined,
              onPressed: () =>
                  context.pushNamed(MaterialUsageReportPageWidget.routeName),
            ),
          action(
            label: tr(context, 'dashboard.action.profitSummary'),
            icon: Icons.account_balance_wallet_outlined,
            onPressed: () =>
                context.pushNamed(ProfitSummaryReportPageWidget.routeName),
          ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.admin'),
        actions: [
          if (canViewUserList(role))
            action(
              label: tr(context, 'dashboard.action.userList'),
              icon: Icons.group_outlined,
              onPressed: () => context.pushNamed(UserListPageWidget.routeName),
            ),
          if (canEditCompanyProfile(role))
            action(
              label: tr(context, 'dashboard.action.companyProfile'),
              icon: Icons.business,
              onPressed: () =>
                  context.pushNamed(CompanySettingPageWidget.routeName),
            ),
          if (canViewAuditLog(role))
            action(
              label: tr(context, 'dashboard.action.auditLog'),
              icon: Icons.history,
              onPressed: () => context.pushNamed(AuditLogPageWidget.routeName),
            ),
          if (isSuperAdminRole(role))
            action(
              label: tr(context, 'dashboard.action.industrySettings'),
              icon: Icons.tune,
              onPressed: () =>
                  context.pushNamed(IndustrySettingsPageWidget.routeName),
            ),
          if (isSuperAdminRole(role))
            action(
              label: tr(context, 'dashboard.action.registrationRequests'),
              icon: Icons.how_to_reg_outlined,
              onPressed: () => context.pushNamed(
                RegistrationRequestsPageWidget.routeName,
              ),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.account'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.logout'),
            icon: Icons.logout,
            onPressed: () => context.pushNamed(LoginPageWidget.routeName),
          ),
        ],
      ),
    ];

    return sections
        .where((section) => section.actions.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _showDashboardMenuSheet(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final sections = _dashboardMenuSections(context);
    final actionCount =
        sections.fold<int>(0, (sum, section) => sum + section.actions.length);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: EmberBrand.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(EmberBrand.radiusLg)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.7;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.menu, color: EmberBrand.navy),
                    const SizedBox(width: 10),
                    Text(
                      tr(sheetContext, 'dashboard.menu.title'),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tr(sheetContext, 'dashboard.menu.actionCount',
                          params: {'count': '$actionCount'}),
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.alternate),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (var sectionIndex = 0;
                        sectionIndex < sections.length;
                        sectionIndex++) ...[
                      if (sectionIndex > 0)
                        Divider(height: 1, color: theme.alternate),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          sections[sectionIndex].title,
                          style: theme.labelLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                            ),
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                      for (final action in sections[sectionIndex].actions)
                        ListTile(
                          leading: Icon(action.icon, color: EmberBrand.electricBlue),
                          title: Text(action.label),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            action.onPressed();
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardMenuSection {
  const _DashboardMenuSection({
    required this.title,
    required this.actions,
  });

  final String title;
  final List<_DashboardMenuAction> actions;
}

class _DashboardMenuAction {
  const _DashboardMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}
