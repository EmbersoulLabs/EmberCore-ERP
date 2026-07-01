import '/auth/role_helpers.dart';
import '/components/home_nav_button.dart';
import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/flutter_flow/nav/nav.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/product_category_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/product_export_helpers.dart';
import '/backend/product_selection_helpers.dart';
import '/components/product_import_button.dart';
import '/components/product_list_item_editor.dart';
import '/components/product_search_filter_panel.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/index.dart';
import 'productlist_model.dart';
export 'productlist_model.dart';

/// Product list — tap a row to open the edit page.
class ProductlistWidget extends StatefulWidget {
  const ProductlistWidget({
    super.key,
    this.productRef,
  });

  final DocumentReference? productRef;

  static String routeName = 'Productlist';
  static String routePath = '/productlist';

  @override
  State<ProductlistWidget> createState() => _ProductlistWidgetState();
}

class _ProductlistWidgetState extends State<ProductlistWidget> {
  late ProductlistModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _bulkUpdating = false;
  bool _exportingCsv = false;
  List<ProductRecord> _filteredProductsCache = const [];

  bool get _canEdit =>
      canEditProducts(AppStateNotifier.instance.userRole);

  bool get _canCreate =>
      canCreateProducts(AppStateNotifier.instance.userRole);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductlistModel());

    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _toggleProductSelection(ProductRecord product, bool? selected) {
    safeSetState(() {
      final path = product.reference.path;
      if (selected == true) {
        _model.selectedProductPaths.add(path);
      } else {
        _model.selectedProductPaths.remove(path);
      }
    });
  }

  bool? _selectAllValue(List<ProductRecord> products) {
    if (products.isEmpty) {
      return false;
    }
    final selectedCount = products
        .where((p) => _model.selectedProductPaths.contains(p.reference.path))
        .length;
    if (selectedCount == 0) {
      return false;
    }
    if (selectedCount == products.length) {
      return true;
    }
    return null;
  }

  void _toggleSelectAll(List<ProductRecord> products, bool? value) {
    safeSetState(() {
      final selectAll = value == true;
      for (final product in products) {
        final path = product.reference.path;
        if (selectAll) {
          _model.selectedProductPaths.add(path);
        } else {
          _model.selectedProductPaths.remove(path);
        }
      }
    });
  }

  Future<void> _bulkSetAllowZeroStock({
    required List<ProductRecord> selected,
    required bool allowZeroStock,
  }) async {
    if (selected.isEmpty || _bulkUpdating) {
      return;
    }

    safeSetState(() => _bulkUpdating = true);
    try {
      await bulkUpdateProductAllowZeroStock(
        productRefs: selected.map((p) => p.reference).toList(),
        allowZeroStock: allowZeroStock,
      );
      if (!mounted) {
        return;
      }
      safeSetState(() => _model.selectedProductPaths.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'product.list.allowZeroUpdated',
              params: {'count': '${selected.length}'},
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'product.list.allowZeroFailed',
              params: {'error': describeFirestoreError(error)},
            ),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        safeSetState(() => _bulkUpdating = false);
      }
    }
  }

  Future<void> _exportFilteredProducts() async {
    if (_exportingCsv) {
      return;
    }
    final products = _filteredProductsCache;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'product.list.exportNoMatch')),
        ),
      );
      return;
    }

    safeSetState(() => _exportingCsv = true);
    try {
      await downloadProductsCsv(
        context: context,
        products: products,
        filenameBase: 'products_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'product.list.exportedSnack',
              params: {'count': '${products.length}'},
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'product.list.exportFailed',
              params: {'error': '$error'},
            ),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        safeSetState(() => _exportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 0.0, 0.0),
            child: Text(
              tr(context, 'product.list.title'),
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    font: GoogleFonts.interTight(),
                    color: Colors.white,
                    fontSize: 22.0,
                  ),
            ),
          ),
          actions: const [
            AppBarLanguageHomeActions(),
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr(context, 'product.list.heading'),
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            ),
                            if (_canEdit)
                              Tooltip(
                                message:
                                    tr(context, 'product.category.manageTitle'),
                                child: FlutterFlowIconButton(
                                  borderRadius: 20.0,
                                  buttonSize: 40.0,
                                  icon: Icon(
                                    Icons.category_outlined,
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    size: 24.0,
                                  ),
                                  onPressed: () =>
                                      showManageProductCategoriesDialog(
                                          context),
                                ),
                              ),
                            if (_canEdit)
                              Tooltip(
                                message: tr(
                                    context, 'product.list.exportTooltip'),
                                child: FlutterFlowIconButton(
                                  borderRadius: 20.0,
                                  buttonSize: 40.0,
                                  icon: _exportingCsv
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.download_outlined,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          size: 24.0,
                                        ),
                                  onPressed: _exportingCsv
                                      ? null
                                      : _exportFilteredProducts,
                                ),
                              ),
                            if (_canCreate)
                              Tooltip(
                                message: tr(
                                    context, 'product.list.importTooltip'),
                                child: FlutterFlowIconButton(
                                  borderRadius: 20.0,
                                  buttonSize: 40.0,
                                  icon: Icon(
                                    Icons.upload_file_outlined,
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    size: 24.0,
                                  ),
                                  onPressed: () =>
                                      pickAndImportProducts(context),
                                ),
                              ),
                            if (_canCreate)
                              FlutterFlowIconButton(
                                borderRadius: 20.0,
                                buttonSize: 40.0,
                                icon: Icon(
                                  Icons.add_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  context.pushNamed(
                                      ProductcreateWidget.routeName);
                                },
                              ),
                          ],
                        ),
                        if (_canCreate)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              tr(context, 'product.list.importHint'),
                              textAlign: TextAlign.center,
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ProductRecord>>(
                  stream: queryTenantProductRecord().map((products) {
                    final sorted = [...products];
                    sorted.sort(
                      (a, b) => a.name
                          .toLowerCase()
                          .compareTo(b.name.toLowerCase()),
                    );
                    return sorted;
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          tr(context, 'common.errorDetail',
                              params: {'error': '${snapshot.error}'}),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      );
                    }
                    final products = snapshot.data!;
                    if (products.isEmpty) {
                      return Center(
                        child: Text(tr(context, 'product.list.empty')),
                      );
                    }

                    final filteredProducts = applyProductSelectionFilters(
                      products: products,
                      searchQuery: _model.searchController?.text ?? '',
                      category: _model.selectedCategory,
                    );
                    _filteredProductsCache = filteredProducts;
                    _model.pruneSelection(products);

                    final selectedProducts =
                        _model.selectedProducts(filteredProducts);

                    return StreamBuilder<List<String>>(
                      stream: streamTenantProductCategories(),
                      builder: (context, categorySnapshot) {
                        final categories = mergeProductCategoryOptions(
                          managedCategories:
                              categorySnapshot.data ?? defaultProductCategories,
                          productCategories: extractProductCategories(products),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ProductSearchFilterPanel(
                              searchController: _model.searchController!,
                              searchFocusNode: _model.searchFocusNode!,
                              selectedCategory: _model.selectedCategory,
                              categories: categories,
                              onSearchChanged: () => setState(() {}),
                              onCategoryChanged: (category) {
                                setState(() => _model.selectedCategory = category);
                              },
                            ),
                            if (_canEdit && filteredProducts.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      tristate: true,
                                      value: _selectAllValue(filteredProducts),
                                      onChanged: _bulkUpdating
                                          ? null
                                          : (value) => _toggleSelectAll(
                                                filteredProducts,
                                                value,
                                              ),
                                    ),
                                    Text(
                                      tr(context, 'common.selectAll'),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium,
                                    ),
                                    const Spacer(),
                                    if (selectedProducts.isNotEmpty)
                                      Text(
                                        '${selectedProducts.length}',
                                        style: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              color: FlutterFlowTheme.of(context)
                                                  .primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: filteredProducts.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          tr(context, 'product.select.noMatch'),
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding:
                                          const EdgeInsets.only(bottom: 24.0),
                                      itemCount: filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = filteredProducts[index];
                                        if (_canEdit) {
                                          return ProductListItemEditor(
                                            key: ValueKey(product.reference.path),
                                            product: product,
                                            selected: _model.selectedProductPaths
                                                .contains(product.reference.path),
                                            onSelectionChanged: _bulkUpdating
                                                ? null
                                                : (checked) =>
                                                    _toggleProductSelection(
                                                      product,
                                                      checked,
                                                    ),
                                          );
                                        }
                                        return ListTile(
                                          key: ValueKey(product.reference.path),
                                          leading: buildZoomableProductImage(
                                            context: context,
                                            imageUrl:
                                                productImageFromRecord(product),
                                            productRef: product.reference,
                                            title: product.name,
                                            width: 48.0,
                                            height: 48.0,
                                          ),
                                          title: Text(product.name),
                                          subtitle: Text(
                                            '\$${product.price.toStringAsFixed(2)} · '
                                            '${product.isActive ? tr(context, 'common.active') : tr(context, 'common.inactive')}',
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            if (_canEdit)
                              SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16.0,
                                    8.0,
                                    16.0,
                                    8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FFButtonWidget(
                                          onPressed: _bulkUpdating ||
                                                  selectedProducts.isEmpty
                                              ? null
                                              : () => _bulkSetAllowZeroStock(
                                                    selected: selectedProducts,
                                                    allowZeroStock: true,
                                                  ),
                                          text: tr(
                                            context,
                                            'product.list.allowZeroOn',
                                          ),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                          ),
                                          options: FFButtonOptions(
                                            height: 48,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FFButtonWidget(
                                          onPressed: _bulkUpdating ||
                                                  selectedProducts.isEmpty
                                              ? null
                                              : () => _bulkSetAllowZeroStock(
                                                    selected: selectedProducts,
                                                    allowZeroStock: false,
                                                  ),
                                          text: tr(
                                            context,
                                            'product.list.allowZeroOff',
                                          ),
                                          icon: const Icon(
                                            Icons.block,
                                            color: Colors.white,
                                          ),
                                          options: FFButtonOptions(
                                            height: 48,
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .override(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
