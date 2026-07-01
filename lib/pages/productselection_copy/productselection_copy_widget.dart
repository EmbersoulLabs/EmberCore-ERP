import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/custom_product_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/product_category_helpers.dart';
import '/backend/product_selection_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/backend/order_checkout_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/components/remark_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import '/theme/ember_brand.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'productselection_copy_model.dart';
export 'productselection_copy_model.dart';

/// Build a Product Selection Page in FlutterFlow using Firebase Firestore.
///
/// Collections:
/// product: name (String), price (Double), image (Image), sku (String),
/// isActive (Boolean)
/// order_items: orderRef (Ref orders), productRef (Ref product), name
/// (String), price (Double), qty (Int), subtotal (Double)
/// Page parameter:
/// orderRef (Document Reference to orders)
/// UI:
/// Display products using GridView or ListView
/// Query only products where isActive == true
/// Each product card shows image, name, price, and â€œAddâ€ button
/// Add button action:
/// If order_items exists for same orderRef + productRef, increase qty and
/// update subtotal
/// Else create new order_items with qty = 1 and subtotal = price
/// Show Snackbar confirmation
/// Bottom section:
/// Show total qty and total amount
/// Button â€œCashierâ€: update orders.order_type = "cashier", go to POS page
/// Button â€œDeliveryâ€: update orders.order_type = "delivery", go to delivery
/// form
class ProductselectionCopyWidget extends StatefulWidget {
  const ProductselectionCopyWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'ProductselectionCopy';
  static String routePath = '/productselectionCopy';

  @override
  State<ProductselectionCopyWidget> createState() =>
      _ProductselectionCopyWidgetState();
}

class _ProductselectionCopyWidgetState
    extends State<ProductselectionCopyWidget> {
  late ProductselectionCopyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _tenantReady = false;

  /// Cached once per page visit â€” avoids re-subscribing Firestore listeners on
  /// every rebuild (search/filter), which can trigger web SDK ca9/b815 asserts.
  Stream<List<ProductRecord>>? _activeProductsStream;
  Stream<List<String>>? _tenantCategoriesStream;
  Stream<OrdersRecord>? _orderStream;
  Stream<List<OrderItemRecord>>? _orderItemsStream;
  bool _customProductExpanded = false;

  void _ensureTenantStreams() {
    _activeProductsStream ??= queryActiveProductsForTenant();
    _tenantCategoriesStream ??= streamTenantProductCategories();
    final orderRef = widget.orderRef;
    if (orderRef != null) {
      _orderStream ??= OrdersRecord.getDocument(orderRef);
      _orderItemsStream ??= streamOrderLineItemsForOrder(orderRef);
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductselectionCopyModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController(text: '1');
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      if (mounted) {
        _ensureTenantStreams();
        safeSetState(() => _tenantReady = true);
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderRef == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'product.select.title')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              tr(context, 'product.select.missingOrderRef'),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              automaticallyImplyLeading: false,
              leading: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 30.0,
                borderWidth: 1.0,
                buttonSize: 60.0,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () {
                  context.safePop();
                },
              ),
              title: Text(
                tr(context, 'product.select.title'),
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    ),
              ),
              actions: const [
                AppBarLanguageHomeActions(),
              ],
              centerTitle: true,
              elevation: 2.0,
            ),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: SafeArea(
              top: true,
              child: !_tenantReady
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<ProductRecord>>(
                        stream: _activeProductsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  tr(context, 'product.select.loadError',
                                      params: {'error': '${snapshot.error}'}),
                                  textAlign: TextAlign.center,
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
                          List<ProductRecord> listViewProductRecordList =
                              snapshot.data!;
                          if (listViewProductRecordList.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  tr(context, 'product.select.noActive'),
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium,
                                ),
                              ),
                            );
                          }

                          final filteredProducts = applyProductSelectionFilters(
                            products: listViewProductRecordList,
                            searchQuery: _model.searchController?.text ?? '',
                            category: _model.selectedCategory,
                          );

                          return StreamBuilder<List<String>>(
                            stream: _tenantCategoriesStream,
                            builder: (context, categorySnapshot) {
                              final categories = mergeProductCategoryOptions(
                                managedCategories: categorySnapshot.data ??
                                    defaultProductCategories,
                                productCategories: extractProductCategories(
                                  listViewProductRecordList,
                                ),
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildProductSearchAndFilter(
                                    context,
                                    categories: categories,
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (filteredProducts.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Text(
                                                tr(context,
                                                    'product.select.noMatch'),
                                                textAlign: TextAlign.center,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium,
                                              ),
                                            )
                                          else
                                            _buildProductSelectionGrid(
                                              context,
                                              filteredProducts,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildProductSelectionFooter(context),
                                ],
                              );
                            },
                          );
                        },
                      ),
            ),
            ),
        );
  }

  Widget _buildProductSelectionFooter(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EmberBrand.card,
        border: const Border(top: BorderSide(color: EmberBrand.border)),
        boxShadow: [
          BoxShadow(
            color: EmberBrand.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: EmberBrand.background,
              borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(
                  () => _customProductExpanded = !_customProductExpanded,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_box_outlined,
                        size: 20,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(context, 'product.select.addCustomProduct'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: EmberBrand.navy,
                          ),
                        ),
                      ),
                      Icon(
                        _customProductExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: EmberBrand.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildCustomProductForm(context, wide: wide),
              ),
              crossFadeState: _customProductExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 12),
            _buildCartSummaryBar(context),
            const SizedBox(height: 12),
            Text(
              tr(context, 'product.select.chooseMethod'),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EmberBrand.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            _buildOrderMethodSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomProductForm(BuildContext context, {required bool wide}) {
    final theme = FlutterFlowTheme.of(context);

    Future<void> createCustom() async {
      final qty = int.tryParse(_model.textController4?.text.trim() ?? '');
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'product.stock.qtyRequired')),
          ),
        );
        return;
      }
      final added = await submitCustomProductWithPhotoChoice(
        context: context,
        orderRef: widget!.orderRef,
        name: _model.textController1.text,
        qty: qty,
        price: double.tryParse(_model.textController3.text),
        remark: _model.textController2.text,
      );
      if (!added || !context.mounted) {
        return;
      }
      _model.textController1?.clear();
      _model.textController2?.clear();
      _model.textController3?.clear();
      _model.textController4?.text = '1';
      setState(() => _customProductExpanded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'product.select.addedToCart')),
          duration: const Duration(milliseconds: 3000),
          backgroundColor: EmberBrand.teal,
        ),
      );
    }

    final nameField = _buildFooterField(
      context,
      controller: _model.textController1,
      focusNode: _model.textFieldFocusNode1,
      hint: tr(context, 'product.select.customName'),
      validator: _model.textController1Validator,
      textInputAction: TextInputAction.next,
    );
    final remarkField = _buildFooterField(
      context,
      controller: _model.textController2,
      focusNode: _model.textFieldFocusNode2,
      hint: tr(context, 'product.select.remark'),
      validator: _model.textController2Validator,
      textInputAction: TextInputAction.next,
    );
    final priceField = _buildFooterField(
      context,
      controller: _model.textController3,
      focusNode: _model.textFieldFocusNode3,
      hint: tr(context, 'product.form.price'),
      validator: _model.textController3Validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
    );
    final qtyField = _buildFooterField(
      context,
      controller: _model.textController4,
      focusNode: _model.textFieldFocusNode4,
      hint: tr(context, 'product.stock.qty'),
      validator: _model.textController4Validator,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: nameField),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: remarkField),
          const SizedBox(width: 8),
          SizedBox(width: 72, child: qtyField),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: priceField),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: createCustom,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(tr(context, 'product.select.createCustom')),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nameField,
        const SizedBox(height: 8),
        remarkField,
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 80, child: qtyField),
            const SizedBox(width: 8),
            Expanded(child: priceField),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: createCustom,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(tr(context, 'product.select.createCustom')),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartSummaryBar(BuildContext context) {
    final orderRef = widget.orderRef;
    if (orderRef == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<OrderItemRecord>>(
      stream: _orderItemsStream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: EmberBrand.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
              border: Border.all(
                color: EmberBrand.amber.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 18,
                  color: EmberBrand.amber.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(context, 'product.select.emptyCart'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: EmberBrand.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final total = functions.calculationTotal(
          items.map((e) => e.price).toList(),
          items.map((e) => e.qty).toList(),
        );
        final qty = items.fold<int>(0, (sum, item) => sum + item.qty);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: EmberBrand.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
            border: Border.all(
              color: EmberBrand.teal.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart_checkout_outlined,
                size: 18,
                color: EmberBrand.teal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(
                    context,
                    'product.select.cartSummary',
                    params: {
                      'count': '$qty',
                      'total': EmberBrand.formatMoney(total),
                    },
                  ),
                  style: GoogleFonts.interTight(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EmberBrand.navy,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildOrderMethodSelector(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final orderRef = widget.orderRef!;

    return StreamBuilder<OrdersRecord>(
      stream: _orderStream,
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tr(context, 'product.select.orderLoadError',
                  params: {'error': '${orderSnapshot.error}'}),
              style: theme.bodySmall.override(color: theme.error),
            ),
          );
        }

        return StreamBuilder<List<OrderItemRecord>>(
          stream: _orderItemsStream,
          builder: (context, itemsSnapshot) {
            if (itemsSnapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr(context, 'product.select.cartLoadError',
                      params: {
                        'error': describeFirestoreError(itemsSnapshot.error!),
                      }),
                  style: theme.bodySmall.override(color: theme.error),
                ),
              );
            }

            final waitingForOrder = orderSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !orderSnapshot.hasData;
            final waitingForItems = itemsSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !itemsSnapshot.hasData;

            if (waitingForOrder || waitingForItems) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final order = orderSnapshot.data;
            if (order == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr(context, 'product.select.orderNotFound'),
                  style: theme.bodySmall.override(color: theme.error),
                ),
              );
            }

            final orderItems = itemsSnapshot.data ?? const [];
            final hasOrderItems = orderItems.isNotEmpty;

            return Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.safePop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: EmberBrand.navy,
                      side: const BorderSide(color: EmberBrand.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(EmberBrand.radiusMd),
                      ),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOrderMethodButton(
                    context,
                    enabled: hasOrderItems,
                    icon: Icons.point_of_sale_outlined,
                    label: tr(context, 'product.select.retail'),
                    onPressed: () => runProductSelectionAction(
                      context,
                      () async {
                        final retailOrderId =
                            OrderIdService.isRetailOrderId(order.orderId)
                                ? order.orderId
                                : await OrderIdService.nextRetailOrderId();
                        await stampOrderCompanyRefBeforeCheckout(orderRef);
                        final freshOrder =
                            await OrdersRecord.getDocumentOnce(orderRef);
                        await orderRef.update(
                          buildOrderCheckoutPatch(
                            freshOrder,
                            {
                              ...createTenantOrdersRecordData(
                                orderType: 'Retail',
                                orderId: retailOrderId,
                                pickupDelivery: 'Retail',
                                deliveryDate: freshOrder.createdTime ??
                                    getCurrentTimestamp,
                              ),
                              ...createOrderStatusUpdateData(
                                OrderStatus.completed,
                              ),
                            },
                          ),
                        );
                        final createdOrder =
                            await OrdersRecord.getDocumentOnce(orderRef);
                        await auditLogCreateOrder(createdOrder);

                        context.pushNamed(
                          RetailSummaryWidget.routeName,
                          queryParameters: {
                            'orderRef': serializeParam(
                              orderRef,
                              ParamType.DocumentReference,
                            ),
                          }.withoutNulls,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOrderMethodButton(
                    context,
                    enabled: hasOrderItems,
                    icon: Icons.local_shipping_outlined,
                    label: tr(context, 'product.select.deliveryPickUp'),
                    accent: EmberBrand.teal,
                    onPressed: () => runProductSelectionAction(
                      context,
                      () async {
                        final deliveryOrderId =
                            OrderIdService.isDeliveryOrderId(order.orderId)
                                ? order.orderId
                                : await OrderIdService.nextDeliveryOrderId();
                        final deliverySaleTotal = functions.calculationTotal(
                          orderItems.map((e) => e.price).toList(),
                          orderItems.map((e) => e.qty).toList(),
                        );
                        await stampOrderCompanyRefBeforeCheckout(orderRef);
                        final freshOrder =
                            await OrdersRecord.getDocumentOnce(orderRef);
                        await orderRef.update(
                          buildOrderCheckoutPatch(
                            freshOrder,
                            {
                              ...createTenantOrdersRecordData(
                                clientName: freshOrder.clientName,
                                orderId: deliveryOrderId,
                                pickupDelivery: 'Delivery',
                                totalAmount: deliverySaleTotal,
                                total: deliverySaleTotal,
                                productSelection: orderItems.isNotEmpty
                                    ? orderItems.first.reference
                                    : null,
                                totalQty: functions.calculateTotalItem(
                                  orderItems.length,
                                ),
                                orderType: 'Delivery',
                              ),
                              ...createOrderStatusUpdateData(
                                OrderStatus.pending,
                              ),
                            },
                          ),
                        );
                        final createdOrder =
                            await OrdersRecord.getDocumentOnce(orderRef);
                        await auditLogCreateOrder(createdOrder);

                        context.pushNamed(
                          CreateOrderFormWidget.routeName,
                          queryParameters: {
                            'orderRef': serializeParam(
                              orderRef,
                              ParamType.DocumentReference,
                            ),
                          }.withoutNulls,
                          extra: <String, dynamic>{
                            'orderRef': orderRef,
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _footerInputDecoration(BuildContext context, String hint) {
    final theme = FlutterFlowTheme.of(context);
    final radius = BorderRadius.circular(10);
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: theme.labelMedium.override(color: theme.secondaryText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: EmberBrand.border),
        borderRadius: radius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.primary, width: 1.5),
        borderRadius: radius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.error),
        borderRadius: radius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.error, width: 1.5),
        borderRadius: radius,
      ),
      filled: true,
      fillColor: EmberBrand.background,
    );
  }

  Widget _buildFooterField(
    BuildContext context, {
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String hint,
    required String? Function(BuildContext, String?)? validator,
    TextInputAction textInputAction = TextInputAction.done,
    TextInputType? keyboardType,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      decoration: _footerInputDecoration(context, hint),
      style: theme.bodyMedium,
      cursorColor: theme.primary,
      validator: validator?.asValidator(context),
    );
  }

  Widget _buildOrderMethodButton(
    BuildContext context, {
    required bool enabled,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? accent,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final bg = accent ?? theme.primary;
    final foreground = enabled ? Colors.white : EmberBrand.textSecondary;
    return Material(
      color: enabled ? bg : EmberBrand.border.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSearchAndFilter(
    BuildContext context, {
    required List<String> categories,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final hasSearchText = _model.searchController!.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _model.searchController,
            focusNode: _model.searchFocusNode,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: tr(context, 'product.select.searchHint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _model.searchController!.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.alternate),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.alternate),
              ),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, 'product.select.category'),
                style: theme.labelMedium.override(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(tr(context, 'common.all')),
                    selected: _model.selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _model.selectedCategory = null);
                    },
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _model.selectedCategory == category,
                        onSelected: (_) {
                          setState(() => _model.selectedCategory = category);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addCatalogProductToOrder(
    BuildContext context,
    ProductRecord product,
  ) async {
    if (widget.orderRef == null) {
      return;
    }
    final blocked = await TenantContext.instance.ensureReadyForTenantWrite();
    if (blocked != null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocked),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }
    DocumentReference? addedItemRef;
    try {
      addedItemRef = await addCatalogProductToOrderItem(
        orderRef: widget.orderRef!,
        product: product,
        qty: 1,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'product.select.addError',
                params: {'error': describeFirestoreError(e)}),
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          alignment: AlignmentDirectional(0.0, 0.0)
              .resolve(Directionality.of(context)),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(dialogContext).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: RemarkWidget(
              orderRef: widget.orderRef!,
              orderItemRef: addedItemRef,
            ),
          ),
        );
      },
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, 'product.select.addedToCart'),
          style: TextStyle(
            color: FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        duration: const Duration(milliseconds: 4000),
        backgroundColor: FlutterFlowTheme.of(context).secondary,
      ),
    );
  }

  Widget _buildProductSelectionGrid(
    BuildContext context,
    List<ProductRecord> products,
  ) {
    const gridRows = 2;
    const crossAxisSpacing = 8.0;
    const mainAxisSpacing = 8.0;
    const itemWidth = 152.0;
    const itemHeight = 196.0;
    final gridHeight =
        gridRows * itemHeight + (gridRows - 1) * crossAxisSpacing;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridRows,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: itemHeight / itemWidth,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductGridCard(context, products[index]);
        },
      ),
    );
  }

  Widget _buildProductGridCard(BuildContext context, ProductRecord product) {
    final theme = FlutterFlowTheme.of(context);
    final priceText = formatNumber(
      product.price,
      formatType: FormatType.decimal,
      decimalType: DecimalType.automatic,
      currency: '',
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: theme.alternate.withValues(alpha: 0.25),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return buildZoomableProductImage(
                    context: context,
                    imageUrl: productImageFromRecord(product),
                    productRef: product.reference,
                    title: product.name,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.contain,
                    placeholderIcon: Icons.local_florist_outlined,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall,
            ),
          ),
          if (product.sku.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                product.sku,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.override(
                  fontSize: 11,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
            child: Text(
              '\$$priceText',
              style: theme.labelMedium.override(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: FFButtonWidget(
              onPressed: () => _addCatalogProductToOrder(context, product),
              text: tr(context, 'common.add'),
              options: FFButtonOptions(
                width: double.infinity,
                height: 32,
                color: theme.primary,
                textStyle: theme.titleSmall.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
