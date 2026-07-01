import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'sales_report_page_model.dart';
export 'sales_report_page_model.dart';

class SalesReportPageWidget extends StatefulWidget {
  const SalesReportPageWidget({super.key});

  static String routeName = 'SalesReportPage';
  static String routePath = '/salesReportPage';

  @override
  State<SalesReportPageWidget> createState() => _SalesReportPageWidgetState();
}

class _SalesReportPageWidgetState extends State<SalesReportPageWidget> {
  late SalesReportPageModel _model;
  final _currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final _dateLabel = DateFormat('EEE, d MMM yyyy');

  DailySalesReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SalesReportPageModel());
    _resetToToday();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadReport();
    });
  }

  void _resetToToday() {
    final today = calendarDay(DateTime.now());
    _model.startDate = today;
    _model.endDate = today;
  }

  DateTime get _startDate =>
      calendarDay(_model.startDate ?? DateTime.now());

  DateTime get _endDate => calendarDay(_model.endDate ?? DateTime.now());

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await buildDailySalesReportRange(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report;
        _loading = false;
      });
      await auditLogExportSalesReport(
        startDate: _startDate,
        endDate: _endDate,
        totalOrders: report.totalOrders,
        totalSales: report.totalSalesAmount,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required String helpText,
  }) async {
    final today = calendarDay(DateTime.now());
    return showDatePicker(
      context: context,
      helpText: helpText,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2020),
      lastDate: today,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(
      initial: _startDate,
      helpText: tr(context, 'report.selectStartDate'),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _model.startDate = calendarDay(picked);
      if (_model.endDate != null &&
          calendarDay(_model.endDate!).isBefore(_model.startDate!)) {
        _model.endDate = _model.startDate;
      }
    });
    await _loadReport();
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(
      initial: _endDate,
      helpText: tr(context, 'report.selectEndDate'),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _model.endDate = calendarDay(picked);
      if (_model.startDate != null &&
          calendarDay(_model.startDate!).isAfter(_model.endDate!)) {
        _model.startDate = _model.endDate;
      }
    });
    await _loadReport();
  }

  Future<void> _refreshToday() async {
    setState(_resetToToday);
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final start = _startDate;
    final end = _endDate;
    final isToday = isTodayDateRange(start, end);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.primaryText,
              size: 30.0,
            ),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            tr(context, 'report.sales.title'),
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              fontSize: 22.0,
            ),
          ),
          actions: [
            FlutterFlowIconButton(
              borderRadius: 20.0,
              buttonSize: 40.0,
              icon: Icon(Icons.refresh, color: theme.primaryText, size: 24.0),
              onPressed: _loading ? null : _refreshToday,
            ),
            const HomeNavIconButton(),
          ],
          elevation: 0.0,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError(theme)
                  : RefreshIndicator(
                      onRefresh: _refreshToday,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDateRangeSelector(
                              theme,
                              start: start,
                              end: end,
                              isToday: isToday,
                            ),
                            const SizedBox(height: 20),
                            _buildSummaryCards(theme),
                            if (_report!.dayOverDayComparison != null) ...[
                              const SizedBox(height: 12),
                              _buildDayOverDayCard(theme),
                            ],
                            if (_report!.hasUnpaidOrders) ...[
                              const SizedBox(height: 12),
                              _buildUnpaidAlert(theme),
                            ],
                            const SizedBox(height: 20),
                            _buildTopProductsSection(theme),
                            const SizedBox(height: 20),
                            _buildHourlyChartSection(theme),
                            const SizedBox(height: 20),
                            _buildProductSection(theme),
                            const SizedBox(height: 20),
                            Text(
                              tr(context, 'report.paymentMethods'),
                              style: theme.titleMedium.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentSection(theme),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildError(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadReport,
              child: Text(tr(context, 'common.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(
    FlutterFlowTheme theme, {
    required DateTime start,
    required DateTime end,
    required bool isToday,
  }) {
    final sameDay = calendarDay(start) == calendarDay(end);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isToday
              ? tr(context, 'report.dateRangeToday')
              : tr(context, 'report.dateRange'),
          style: theme.labelMedium.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateTile(
                theme,
                label: tr(context, 'report.dateFrom'),
                date: start,
                onTap: _pickStartDate,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, color: theme.secondaryText),
            ),
            Expanded(
              child: _buildDateTile(
                theme,
                label: tr(context, 'report.dateTo'),
                date: end,
                onTap: _pickEndDate,
              ),
            ),
          ],
        ),
        if (!sameDay)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_dateLabel.format(start)} – ${_dateLabel.format(end)}',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTile(
    FlutterFlowTheme theme, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelMedium.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateLabel.format(date),
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(FlutterFlowTheme theme) {
    final products = _report!.productBreakdown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'report.products'),
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Text(
              tr(context, 'report.noProductsSold'),
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Column(
              children: [
                _productHeaderRow(context, theme),
                for (var i = 0; i < products.length; i++) ...[
                  Divider(height: 1, color: theme.alternate),
                  _productRow(theme, products[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _productHeaderRow(BuildContext context, FlutterFlowTheme theme) {
    TextStyle headerStyle = theme.labelMedium.override(
      font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
      color: theme.secondaryText,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(tr(context, 'report.productName'), style: headerStyle),
          ),
          Expanded(
            child: Text(
              tr(context, 'common.qty'),
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tr(context, 'report.totalAmount'),
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productRow(FlutterFlowTheme theme, ProductSalesBreakdown row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.productName,
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.totalQty.toString(),
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(row.totalAmount),
              textAlign: TextAlign.right,
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                color: theme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FlutterFlowTheme theme) {
    final report = _report!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                theme,
                label: tr(context, 'report.totalOrders'),
                value: report.totalOrders.toString(),
                icon: Icons.receipt_long_outlined,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                theme,
                label: tr(context, 'report.totalSales'),
                value: _currency.format(report.totalSalesAmount),
                icon: Icons.payments_outlined,
                color: theme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricCard(
          theme,
          label: tr(context, 'report.averageOrderAmount'),
          value: _currency.format(report.averageOrderAmount),
          icon: Icons.calculate_outlined,
          color: theme.secondary,
        ),
      ],
    );
  }

  Widget _buildDayOverDayCard(FlutterFlowTheme theme) {
    final cmp = _report!.dayOverDayComparison!;
    final pct = cmp.changePercent;
    final trendColor = cmp.isFlat
        ? theme.secondaryText
        : cmp.isUp
            ? theme.success
            : theme.error;
    final trendIcon = cmp.isFlat
        ? Icons.remove
        : cmp.isUp
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'report.vsYesterday'),
                  style: theme.labelMedium.override(color: theme.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    context,
                    'report.yesterdaySales',
                    params: {'amount': _currency.format(cmp.previousAmount)},
                  ),
                  style: theme.bodySmall.override(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, color: trendColor, size: 22),
              const SizedBox(width: 6),
              Text(
                pct != null
                    ? '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%'
                    : tr(context, 'report.dayOverDayNew'),
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidAlert(FlutterFlowTheme theme) {
    final report = _report!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.error.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr(
                context,
                'report.unpaidOrdersAlert',
                params: {
                  'count': '${report.unpaidOrdersCount}',
                  'amount': _currency.format(report.unpaidOrdersTotalAmount),
                },
              ),
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                color: theme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(FlutterFlowTheme theme) {
    final top = _report!.topProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'report.topProducts'),
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (top.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Text(
              tr(context, 'report.noTopProducts'),
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < top.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < top.length - 1 ? 8 : 0),
                  child: _topProductCard(theme, rank: i + 1, row: top[i]),
                ),
            ],
          ),
      ],
    );
  }

  Widget _topProductCard(
    FlutterFlowTheme theme, {
    required int rank,
    required ProductSalesBreakdown row,
  }) {
    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final rankColor = rankColors[(rank - 1).clamp(0, 2)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: rankColor.withValues(alpha: 0.25),
            child: Text(
              '$rank',
              style: theme.labelLarge.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w800),
                color: theme.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.productName,
                  style: theme.titleSmall.override(
                    font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tr(context, 'common.qty')}: ${row.totalQty}',
                  style: theme.bodySmall.override(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          Text(
            _currency.format(row.totalAmount),
            style: theme.titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChartSection(FlutterFlowTheme theme) {
    final buckets = _report!.hourlyBreakdown;
    final maxAmount = buckets
        .map((bucket) => bucket.totalAmount)
        .fold(0.0, (a, b) => a > b ? a : b);
    final busiest = buckets.isEmpty
        ? null
        : buckets.reduce(
            (a, b) => a.totalAmount >= b.totalAmount ? a : b,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'report.hourlySales'),
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        if (busiest != null && busiest.totalAmount > 0) ...[
          const SizedBox(height: 4),
          Text(
            tr(
              context,
              'report.busiestHour',
              params: {
                'hour': '${busiest.hour}',
                'nextHour': '${(busiest.hour + 1) % 24}',
              },
            ),
            style: theme.bodySmall.override(color: theme.secondaryText),
          ),
        ],
        const SizedBox(height: 12),
        if (maxAmount <= 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Text(
              tr(context, 'report.hourlySalesEmpty'),
              style: theme.bodyMedium.override(color: theme.secondaryText),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (bucket.totalAmount > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  bucket.orderCount.toString(),
                                  style: theme.labelSmall.override(
                                    color: theme.secondaryText,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            Container(
                              height: (140 * bucket.totalAmount / maxAmount)
                                  .clamp(4, 140),
                              decoration: BoxDecoration(
                                color: bucket.totalAmount == maxAmount
                                    ? theme.primary
                                    : theme.primary.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${bucket.hour}',
                              style: theme.labelSmall.override(
                                color: theme.secondaryText,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _metricCard(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.labelMedium.override(color: theme.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.headlineSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(FlutterFlowTheme theme) {
    final breakdown = _report!.paymentBreakdown;
    if (breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Text(
          tr(context, 'report.noPaidOrders'),
          style: theme.bodyMedium.override(color: theme.secondaryText),
        ),
      );
    }

    return Column(
      children: breakdown
          .map((row) => _paymentRow(theme, row))
          .toList(growable: false),
    );
  }

  Widget _paymentRow(FlutterFlowTheme theme, PaymentMethodBreakdown row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'report.paymentRowTotal',
                        params: {'label': row.label}),
                    style: theme.titleSmall.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.orderCount == 1
                        ? tr(context, 'report.paymentOneOrder',
                            params: {'count': '${row.orderCount}'})
                        : tr(context, 'report.paymentManyOrders',
                            params: {'count': '${row.orderCount}'}),
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _currency.format(row.totalAmount),
              style: theme.titleMedium.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
