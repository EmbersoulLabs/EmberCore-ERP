import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/driver_assignment_helpers.dart';
import '/backend/driver_delivery_filter_helpers.dart';
import '/backend/driver_delivery_tab_labels.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/driver_route_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/components/driver_delivery_order_card.dart';
import '/components/driver_suggested_route_section.dart';
import '/components/ember_app_shell.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/theme/ember_brand.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/google_maps_service.dart';
import '/l10n/locale_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'driver_delivery_page_model.dart';
export 'driver_delivery_page_model.dart';

/// Create a FlutterFlow page named "DriverDeliveryPage" for delivery drivers.
///
/// Purpose:
/// Allow drivers to view, accept, and update delivery orders assigned to
/// them.
///
/// Layout:
/// - AppBar with title "My Deliveries"
/// - Clean, mobile-first layout
/// - Light background, clear spacing
///
/// Content:
/// 1) Filter tabs or chips:
///    - Assigned
///    - Out for Delivery
///    - Completed
///
/// 2) ListView of delivery orders (from Firestore "orders" collection)
///    - Query orders where:
///      - assigned_driver == current authenticated user
///      - order_status in [ready_to_ship, out_for_delivery, completed]
///    - Order by delivery_date ascending
///
/// Each order card shows:
/// - Order Number
/// - Customer Name
/// - Delivery Address
/// - Delivery Time Slot
/// - Current Order Status (badge)
///
/// Actions per order:
/// - If status == ready_to_ship:
///   - Button: "Start Delivery"
///   - Update order_status to out_for_delivery
/// - If status == out_for_delivery:
///   - Button: "Mark as Delivered"
///   - Update order_status to completed
/// - Disable buttons if status == completed
class DriverDeliveryPageWidget extends StatefulWidget {
  const DriverDeliveryPageWidget({super.key});

  static String routeName = 'DriverDeliveryPage';
  static String routePath = '/driverDeliveryPage';

  @override
  State<DriverDeliveryPageWidget> createState() =>
      _DriverDeliveryPageWidgetState();
}

class _DriverDeliveryPageWidgetState extends State<DriverDeliveryPageWidget> {
  late DriverDeliveryPageModel _model;

  DocumentReference? _driverRef;
  bool _profileLoading = true;
  OrderStatus? _tabStatus;
  final _dateLabel = DateFormat('d/M/y');

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DriverDeliveryPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        _driverRef = profile?.reference;
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        safeSetState(() => _profileLoading = false);
      }
    });
  }

  Query Function(Query) _orderQuery() {
    if (_driverRef == null) {
      return (Query query) => query;
    }
    return (Query query) =>
        query.where('assigned_driver', isEqualTo: _driverRef);
  }

  void _onTabChipChanged(String? chip) {
    safeSetState(() {
      _model.choiceChipsValue = chip;
      _tabStatus = driverTabStatusFromChip(chip);
    });
  }

  Future<void> _pickFilterDate({required bool isStart}) async {
    final today = calendarDay(DateTime.now());
    final initial = calendarDay(
      (isStart ? _model.filterStartDate : _model.filterEndDate) ?? today,
    );
    final picked = await showDatePicker(
      context: context,
      helpText: isStart ? 'Filter from date' : 'Filter to date',
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked == null) {
      return;
    }
    safeSetState(() {
      final day = calendarDay(picked);
      if (isStart) {
        _model.filterStartDate = day;
        if (_model.filterEndDate != null &&
            _model.filterEndDate!.isBefore(day)) {
          _model.filterEndDate = day;
        }
      } else {
        _model.filterEndDate = day;
        if (_model.filterStartDate != null &&
            _model.filterStartDate!.isAfter(day)) {
          _model.filterStartDate = day;
        }
      }
    });
  }

  void _clearDateFilter() {
    safeSetState(() {
      _model.filterStartDate = null;
      _model.filterEndDate = null;
    });
  }

  String _dateFilterSummary() {
    final start = _model.filterStartDate;
    final end = _model.filterEndDate;
    if (start == null && end == null) {
      return 'All delivery dates';
    }
    if (start != null && end != null) {
      if (calendarDay(start) == calendarDay(end)) {
        return _dateLabel.format(start);
      }
      return '${_dateLabel.format(start)} – ${_dateLabel.format(end)}';
    }
    if (start != null) {
      return 'From ${_dateLabel.format(start)}';
    }
    return 'Until ${_dateLabel.format(end!)}';
  }

  void _syncStatusFilterChips(BuildContext context) {
    final defaultLabel = DriverDeliveryTabKey.all.label(context);
    _model.choiceChipsValueController ??=
        FormFieldController<List<String>>([defaultLabel]);
    final key = driverDeliveryTabKeyFromLabel(_model.choiceChipsValue);
    if (key == null) {
      _model.choiceChipsValue = defaultLabel;
      _model.choiceChipsValueController!.value = [defaultLabel];
      _tabStatus = null;
    } else {
      _tabStatus = driverTabStatusFromChip(_model.choiceChipsValue);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentKey =
        driverDeliveryTabKeyFromLabel(_model.choiceChipsValue) ??
            DriverDeliveryTabKey.all;
    final localized = currentKey.label(context);
    if (_model.choiceChipsValue != localized) {
      _model.choiceChipsValue = localized;
      _model.choiceChipsValueController?.value = [localized];
    }
    _tabStatus = driverTabStatusFromChip(_model.choiceChipsValue);
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _logout() async {
    await authManager.signOut();
    AppStateNotifier.instance.clearUserRole();
    if (!mounted) {
      return;
    }
    context.go(LoginPageWidget.routePath);
  }

  Future<void> _openSuggestedRoute(List<OrdersRecord> orders) async {
    var addresses = driverRouteAddresses(orders);
    final totalStops = addresses.length;
    if (totalStops == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No delivery addresses to route.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
      return;
    }

    addresses = limitRouteStops(addresses);
    if (totalStops > kDriverRouteMaxStops && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening first $kDriverRouteMaxStops stops in Google Maps.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
    }

    final opened = await GoogleMapsService.openMultiStopRoute(addresses);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open Google Maps.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  bool _showSuggestedRoute(List<OrdersRecord> orders) {
    return driverRouteAddresses(orders).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _syncStatusFilterChips(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: EmberAppShell(
        selectedPath: DriverDeliveryPageWidget.routePath,
        title: loc(
          context,
          en: 'My Deliveries',
          zh: '我的派送',
          ms: 'Penghantaran Saya',
        ),
        subtitle: loc(
          context,
          en: 'All orders assigned to you',
          zh: '所有指派给你的订单',
          ms: 'Semua pesanan ditugaskan kepada anda',
        ),
        extraActions: [
          const HomeNavIconButton.onPrimary(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => safeSetState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async => _logout(),
          ),
        ],
        body: SafeArea(
          top: true,
          child: ListView(
            padding: EdgeInsets.zero,
            primary: false,
            scrollDirection: Axis.vertical,
            children: [
              ListView(
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildDateFilter(context),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 16.0, 0.0),
                        child: FlutterFlowChoiceChips(
                          options: driverDeliveryTabChipOptions(context),
                          onChanged: (val) =>
                              _onTabChipChanged(val?.firstOrNull),
                            selectedChipStyle: ChipStyle(
                              backgroundColor: EmberBrand.electricBlue,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color: Colors.white,
                                  ),
                              iconColor: Colors.white,
                              iconSize: 18.0,
                              labelPadding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 8.0, 16.0, 8.0),
                              elevation: 0.0,
                              borderColor: EmberBrand.electricBlue,
                              borderWidth: 1.0,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            unselectedChipStyle: ChipStyle(
                              backgroundColor: EmberBrand.card,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    color: EmberBrand.textSecondary,
                                  ),
                              iconColor: EmberBrand.textSecondary,
                              iconSize: 18.0,
                              labelPadding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 8.0, 16.0, 8.0),
                              elevation: 0.0,
                              borderColor: EmberBrand.border,
                              borderWidth: 1.0,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            chipSpacing: 12.0,
                            rowSpacing: 8.0,
                            multiselect: false,
                            alignment: WrapAlignment.center,
                            controller: _model.choiceChipsValueController!,
                            wrapped: false,
                          ),
                        ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 16.0, 16.0, 16.0),
                        child: _profileLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _driverRef == null
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Could not load your driver profile. Try logging out and in again.',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                          ),
                                    ),
                                  )
                                : StreamBuilder<List<OrderItemRecord>>(
                                    stream: queryTenantOrderItemRecord(),
                                    builder: (context, itemsSnapshot) {
                                      if (!itemsSnapshot.hasData) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final allItems = itemsSnapshot.data!;

                                      return StreamBuilder<List<OrdersRecord>>(
                          key: ValueKey(
                            'driver-orders-${_tabStatus?.name ?? 'all'}-'
                            '${_driverRef!.path}-'
                            '${_model.filterStartDate?.millisecondsSinceEpoch}-'
                            '${_model.filterEndDate?.millisecondsSinceEpoch}',
                          ),
                          stream: queryTenantOrdersRecord(
                            queryBuilder: _orderQuery(),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Could not load orders: ${snapshot.error}',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(),
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                      ),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  width: 50.0,
                                  height: 50.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      FlutterFlowTheme.of(context).primary,
                                    ),
                                  ),
                                ),
                              );
                            }
                            List<OrdersRecord> listViewOrdersRecordList =
                                filterDriverDeliveryOrders(
                              snapshot.data!,
                              driverRef: _driverRef,
                              tabStatus: _tabStatus,
                              filterStart: _model.filterStartDate,
                              filterEnd: _model.filterEndDate,
                            );

                            final routeOrders = suggestedRouteOrders(
                              driverActiveRouteOrders(
                                snapshot.data!,
                                driverRef: _driverRef,
                                filterStart: _model.filterStartDate,
                                filterEnd: _model.filterEndDate,
                              ),
                            );

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_showSuggestedRoute(routeOrders))
                                  DriverSuggestedRouteSection(
                                    routeOrders: routeOrders,
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
                                    onOpenMaps: () =>
                                        _openSuggestedRoute(routeOrders),
                                  ),
                                if (listViewOrdersRecordList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      'No deliveries match your filters.\n\n'
                                      'Confirm the order is assigned to you, '
                                      'or adjust status / date filters.',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                          ),
                                    ),
                                  ),
                                ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: listViewOrdersRecordList.length,
                              itemBuilder: (context, listViewIndex) {
                                final order =
                                    listViewOrdersRecordList[listViewIndex];
                                final items = orderListItemsForOrder(
                                  allItems,
                                  order,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DriverDeliveryOrderCard(
                                    order: order,
                                    items: items,
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
                                  ),
                                );
                              },
                            ),
                              ],
                            );
                          },
                        );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasFilter =
        _model.filterStartDate != null || _model.filterEndDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Delivery date',
          style: theme.labelMedium.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dateFilterTile(
                context,
                label: 'From',
                value: _model.filterStartDate == null
                    ? 'Any'
                    : _dateLabel.format(_model.filterStartDate!),
                onTap: () => _pickFilterDate(isStart: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dateFilterTile(
                context,
                label: 'To',
                value: _model.filterEndDate == null
                    ? 'Any'
                    : _dateLabel.format(_model.filterEndDate!),
                onTap: () => _pickFilterDate(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _dateFilterSummary(),
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
            ),
            if (hasFilter)
              TextButton(
                onPressed: _clearDateFilter,
                child: const Text('Clear dates'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dateFilterTile(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelSmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
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
}
