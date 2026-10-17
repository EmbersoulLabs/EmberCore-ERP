import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/billing_catalog.dart';
import '/backend/monthly_usage.dart';
import '/backend/schema/companies_record.dart';
import '/backend/stripe_billing_service.dart';
import '/backend/subscription_helpers.dart';
import '/backend/tenant_context.dart';
import '/components/ember_app_shell.dart';
import '/components/ember_section_card.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/theme/ember_navigation.dart';

class BillingPageWidget extends StatefulWidget {
  const BillingPageWidget({super.key});

  static String routeName = 'BillingPage';
  static String routePath = '/billingPage';

  @override
  State<BillingPageWidget> createState() => _BillingPageWidgetState();
}

class _BillingPageWidgetState extends State<BillingPageWidget> {
  CompaniesRecord? _company;
  bool _loading = true;
  String? _loadError;
  bool _checkoutBusy = false;
  String _interval = 'month';
  String? _bannerMessage;
  String? _ordersUsage;
  String? _broadcastUsage;
  bool _trialOrders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readReturnQuery();
      _loadCompany();
    });
  }

  void _readReturnQuery() {
    final billing = GoRouterState.of(context).uri.queryParameters['billing'];
    if (billing == 'success') {
      _bannerMessage = tr(context, 'billing.checkoutSuccess');
    } else if (billing == 'cancelled') {
      _bannerMessage = tr(context, 'billing.checkoutCancelled');
    }
  }

  Future<void> _loadCompany() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final companyRef = TenantContext.instance.writeCompanyRef;
      if (companyRef == null) {
        setState(() {
          _loadError = tr(context, 'billing.loadFailed');
          _loading = false;
        });
        return;
      }
      final snap = await companyRef.get();
      final company = CompaniesRecord.fromSnapshot(snap);
      final raw = snap.data();
      final usage = await _usageLines(
        company,
        raw is Map<String, dynamic> ? raw : <String, dynamic>{},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _company = company;
        _ordersUsage = usage.orders;
        _broadcastUsage = usage.broadcast;
        _trialOrders = usage.trial;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = tr(context, 'billing.loadFailed');
        _loading = false;
      });
    }
  }

  Future<({String? orders, String? broadcast, bool trial})> _usageLines(
    CompaniesRecord company,
    Map<String, dynamic> raw,
  ) async {
    final status = company.subscriptionStatus;
    if (status == 'trialing') {
      final quota = await FirebaseFirestore.instance
          .collection('trial_quota')
          .doc(company.reference.id)
          .get();
      final used = (quota.data()?['orders_consumed'] as num?)?.toInt() ?? 0;
      return (
        orders: '$used / ${company.maxOrdersPerMonth}',
        broadcast: null,
        trial: true,
      );
    }
    if (status != 'active') {
      return (orders: null, broadcast: null, trial: false);
    }
    final end = raw['current_period_end'];
    final period = usagePeriodId(
      nowUtc: DateTime.now().toUtc(),
      storedPeriodId: raw['usage_period_id'] as String?,
      periodEnd: end is Timestamp ? end.toDate() : null,
    );
    final usage = await FirebaseFirestore.instance
        .collection('plan_usage')
        .doc(company.reference.id)
        .get();
    final data = usage.data() ?? {};
    final same = data['period_id'] == period;
    final ordersUsed =
        same ? (data['orders_consumed'] as num?)?.toInt() ?? 0 : 0;
    final broadcastUsed =
        same ? (data['broadcast_consumed'] as num?)?.toInt() ?? 0 : 0;
    final broadcastMax =
        (raw['broadcast_quota_monthly'] as num?)?.toInt() ?? 0;
    return (
      orders: '$ordersUsed / ${company.maxOrdersPerMonth}',
      broadcast: broadcastMax > 0 ? '$broadcastUsed / $broadcastMax' : null,
      trial: false,
    );
  }

  Future<void> _openCheckout(String planTier) async {
    final company = _company;
    if (company == null || _checkoutBusy) {
      return;
    }
    setState(() => _checkoutBusy = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'billing.openingCheckout'))),
      );
    }
    try {
      final result = await createStripeCheckoutSession(
        companyId: company.reference.id,
        planTier: planTier,
        interval: _interval,
      );
      final uri = Uri.parse(result.url);
      final launched = await launchUrl(uri, webOnlyWindowName: '_self');
      if (!launched && mounted) {
        throw Exception('Could not open checkout URL.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'billing.checkoutFailed',
              params: {'error': describeStripeCallableError(error)},
            ),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkoutBusy = false);
      }
    }
  }

  Future<void> _openPortal() async {
    final company = _company;
    if (company == null || _checkoutBusy) {
      return;
    }
    setState(() => _checkoutBusy = true);
    try {
      final result = await createStripePortalSession(
        companyId: company.reference.id,
      );
      final uri = Uri.parse(result.url);
      final launched = await launchUrl(uri, webOnlyWindowName: '_self');
      if (!launched && mounted) {
        throw Exception('Could not open portal URL.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'billing.portalFailed',
              params: {'error': describeStripeCallableError(error)},
            ),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkoutBusy = false);
      }
    }
  }

  String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) {
      return '—';
    }
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canManage = canManageBilling(currentViewerRole());

    return EmberAppShell(
      selectedPath: BillingPageWidget.routePath,
      title: tr(context, 'billing.title'),
      showBackButton: true,
      navGroups: buildEmberNavGroups(context),
      body: !canManage
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr(context, 'billing.noPermission'),
                  style: theme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(child: Text(_loadError!, style: theme.bodyLarge))
                  : RefreshIndicator(
                      onRefresh: _loadCompany,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_bannerMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MaterialBanner(
                                content: Text(_bannerMessage!),
                                leading: const Icon(Icons.info_outline),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _bannerMessage = null);
                                    },
                                    child: Text(tr(context, 'common.close')),
                                  ),
                                ],
                              ),
                            ),
                          EmberSectionCard(
                            title: tr(context, 'billing.currentPlan'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(
                                  context,
                                  tr(context, 'billing.currentPlan'),
                                  tr(
                                    context,
                                    planTierLabelKey(_company?.planTier),
                                  ),
                                ),
                                _infoRow(
                                  context,
                                  tr(context, 'billing.status'),
                                  tr(
                                    context,
                                    subscriptionStatusLabelKey(
                                      _company?.subscriptionStatus,
                                    ),
                                  ),
                                ),
                                if (_company?.trialEndsAt != null)
                                  _infoRow(
                                    context,
                                    tr(context, 'billing.trialEnds'),
                                    _formatDate(context, _company!.trialEndsAt),
                                  ),
                                if (_ordersUsage != null)
                                  _infoRow(
                                    context,
                                    tr(
                                      context,
                                      _trialOrders
                                          ? 'billing.trialOrders'
                                          : 'billing.ordersUsage',
                                    ),
                                    _ordersUsage!,
                                  ),
                                if (_broadcastUsage != null)
                                  _infoRow(
                                    context,
                                    tr(context, 'billing.broadcastUsage'),
                                    _broadcastUsage!,
                                  ),
                                if (_company?.currentPeriodEnd != null)
                                  _infoRow(
                                    context,
                                    tr(context, 'billing.renews'),
                                    _formatDate(
                                      context,
                                      _company!.currentPeriodEnd,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'month',
                                label: Text(tr(context, 'billing.interval.month')),
                              ),
                              ButtonSegment(
                                value: 'year',
                                label: Text(tr(context, 'billing.interval.year')),
                              ),
                            ],
                            selected: {_interval},
                            onSelectionChanged: (selection) {
                              setState(() => _interval = selection.first);
                            },
                          ),
                          if (normalizeBillingCountry(_company?.billingCountry)
                                  .isEmpty ||
                              billingListPriceMinor(
                                    country: _company?.billingCountry,
                                    plan: 'starter',
                                    interval: _interval,
                                  ) ==
                                  null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                tr(context, 'billing.countryMissing'),
                                style: theme.bodyMedium,
                              ),
                            ),
                          const SizedBox(height: 16),
                          _planCard(
                            context,
                            theme,
                            plan: 'starter',
                            titleKey: 'billing.plan.starter',
                            blurbKey: 'billing.starterBlurb',
                            buttonKey: 'billing.subscribeStarter',
                          ),
                          const SizedBox(height: 16),
                          _planCard(
                            context,
                            theme,
                            plan: 'pro',
                            titleKey: 'billing.plan.pro',
                            blurbKey: 'billing.proBlurb',
                            buttonKey: 'billing.subscribePro',
                          ),
                          const SizedBox(height: 16),
                          _planCard(
                            context,
                            theme,
                            plan: 'business',
                            titleKey: 'billing.plan.business',
                            blurbKey: 'billing.businessBlurb',
                            buttonKey: 'billing.subscribeBusiness',
                          ),
                          const SizedBox(height: 16),
                          FFButtonWidget(
                            onPressed:
                                _checkoutBusy || _company?.stripeCustomerId.isEmpty == true
                                    ? null
                                    : _openPortal,
                            text: tr(context, 'billing.managePortal'),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 44,
                              color: theme.secondaryBackground,
                              textStyle: theme.titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: theme.primaryText,
                              ),
                              borderSide: BorderSide(color: theme.alternate),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _planCard(
    BuildContext context,
    FlutterFlowTheme theme, {
    required String plan,
    required String titleKey,
    required String blurbKey,
    required String buttonKey,
  }) {
    final priced = billingListPriceMinor(
          country: _company?.billingCountry,
          plan: plan,
          interval: _interval,
        ) !=
        null;
    return EmberSectionCard(
      title: tr(context, titleKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatBillingPrice(
              country: _company?.billingCountry,
              plan: plan,
              interval: _interval,
            ),
            style: theme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(tr(context, blurbKey), style: theme.bodyMedium),
          const SizedBox(height: 12),
          FFButtonWidget(
            onPressed: _checkoutBusy || !priced ? null : () => _openCheckout(plan),
            text: tr(context, buttonKey),
            options: FFButtonOptions(
              height: 44,
              color: theme.primary,
              textStyle: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                color: Colors.white,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.labelMedium.override(
                color: theme.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.bodyMedium.override(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
