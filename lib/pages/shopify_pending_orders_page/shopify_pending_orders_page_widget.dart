import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/schema/shopify_reviews_record.dart';
import '/backend/shopify_pending_orders_helpers.dart';
import '/backend/shopify_review_approval_api.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/components/order_detail_item_tile.dart';
import '/components/order_list_item_card.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/l10n/tr.dart';

String _financialStatusLabel(BuildContext context, ShopifyReviewsRecord review) {
  final key = shopifyReviewFinancialStatusKey(review);
  final l10nKey = 'order.shopify.financial.$key';
  final label = tr(context, l10nKey);
  return label == l10nKey ? key : label;
}

/// Staging queue for Shopify orders awaiting human admission.
class ShopifyPendingOrdersPageWidget extends StatefulWidget {
  const ShopifyPendingOrdersPageWidget({super.key});

  static String routeName = 'ShopifyPendingOrdersPage';
  static String routePath = '/shopifyPendingOrdersPage';

  @override
  State<ShopifyPendingOrdersPageWidget> createState() =>
      _ShopifyPendingOrdersPageWidgetState();
}

class _ShopifyPendingOrdersPageWidgetState
    extends State<ShopifyPendingOrdersPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};

  List<ShopifyReviewsRecord> _allReviews = const [];
  bool _pendingOnly = true;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _approvingReviewId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadReviews();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final role = AppStateNotifier.instance.userRole;
    if (!canViewOrders(role)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _allReviews = const [];
        _error = '__no_permission__';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reviews = await loadShopifyReviewsForQueue();
      if (!mounted) {
        return;
      }
      setState(() {
        _allReviews = reviews;
        _loading = false;
        _selectedIds.removeWhere(
          (id) => !reviews.any(
            (review) =>
                review.reference.id == id && isShopifyReviewSelectable(review),
          ),
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '__load_failed__';
      });
    }
  }

  List<ShopifyReviewsRecord> get _visibleReviews => filterShopifyReviewsForQueue(
        _allReviews,
        pendingOnly: _pendingOnly,
        searchQuery: _searchController.text,
      );

  List<ShopifyReviewsRecord> get _visibleSelectable => _visibleReviews
      .where(isShopifyReviewSelectable)
      .toList(growable: false);

  bool? _selectAllValue() {
    final selectable = _visibleSelectable;
    if (selectable.isEmpty) {
      return false;
    }
    final selectedCount = selectable
        .where((review) => _selectedIds.contains(review.reference.id))
        .length;
    if (selectedCount == 0) {
      return false;
    }
    if (selectedCount == selectable.length) {
      return true;
    }
    return null;
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        for (final review in _visibleSelectable) {
          _selectedIds.add(review.reference.id);
        }
      } else {
        for (final review in _visibleSelectable) {
          _selectedIds.remove(review.reference.id);
        }
      }
    });
  }

  void _toggleSelected(ShopifyReviewsRecord review, bool? checked) {
    if (!isShopifyReviewSelectable(review)) {
      return;
    }
    setState(() {
      if (checked == true) {
        _selectedIds.add(review.reference.id);
      } else {
        _selectedIds.remove(review.reference.id);
      }
    });
  }

  Future<void> _openOfficialOrder(ShopifyReviewsRecord review) async {
    final orderRef = review.officialOrderRef;
    if (orderRef == null) {
      return;
    }
    await context.pushNamed(
      OrderDetailPageWidget.routeName,
      queryParameters: {
        'orderRef': serializeParam(orderRef, ParamType.DocumentReference)!,
      },
      extra: {'orderRef': orderRef},
    );
    if (mounted) {
      await _loadReviews();
    }
  }

  Future<void> _showDetails(ShopifyReviewsRecord review) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final lineItems = shopifyReviewLineItemMaps(review);
        final perProductCards =
            shopifyReviewShouldShowPerProductCards(lineItems);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shopifyReviewShopifyLabel(review),
                  style: FlutterFlowTheme.of(sheetContext).headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(_financialStatusLabel(sheetContext, review)),
                Text(shopifyReviewCustomer(review)),
                if (shopifyReviewRecipient(review) !=
                    shopifyReviewCustomer(review))
                  Text(
                    '${tr(sheetContext, 'order.col.recipient')}: ${shopifyReviewRecipient(review)}',
                  ),
                if (shopifyReviewSenderPhone(review).isNotEmpty)
                  Text(
                    '${tr(sheetContext, 'order.field.senderPhone')} ${shopifyReviewSenderPhone(review)}',
                  ),
                if (shopifyReviewRecipientPhone(review).isNotEmpty &&
                    shopifyReviewRecipientPhone(review) !=
                        shopifyReviewSenderPhone(review))
                  Text(
                    '${tr(sheetContext, 'order.field.phone')} ${shopifyReviewRecipientPhone(review)}',
                  ),
                if (shopifyReviewDeliveryAddress(review).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${tr(sheetContext, 'order.field.address')} ${shopifyReviewDeliveryAddress(review)}',
                  ),
                ],
                if (shopifyReviewBillingAddress(review).isNotEmpty &&
                    shopifyReviewBillingAddress(review) !=
                        shopifyReviewDeliveryAddress(review)) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${tr(sheetContext, 'order.field.billingAddress')} ${shopifyReviewBillingAddress(review)}',
                  ),
                ],
                if (shopifyReviewScheduleLabel(review).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${tr(sheetContext, 'order.field.deliveryDate')} ${shopifyReviewScheduleLabel(review)}',
                  ),
                ],
                if (!perProductCards &&
                    review.cardMessage.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${tr(sheetContext, 'order.field.cardMessage')} ${review.cardMessage.trim()}',
                  ),
                ],
                if (review.notes.isNotEmpty &&
                    review.notes.trim() != review.cardMessage.trim()) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${tr(sheetContext, 'order.field.remark')} ${review.notes}',
                  ),
                ],
                if (shopifyReviewRemarks(review).isNotEmpty &&
                    shopifyReviewRemarks(review) != review.notes.trim()) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${tr(sheetContext, 'order.field.remark')} ${shopifyReviewRemarks(review)}',
                  ),
                ],
                if (shopifyReviewAddons(review).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${tr(sheetContext, 'order.field.addon')} ${shopifyReviewAddons(review).join(', ')}',
                  ),
                ],
                const SizedBox(height: 12),
                ...lineItems.map((item) {
                  final title = shopifyReviewLineItemTitle(item);
                  final variant = shopifyReviewLineItemVariant(item);
                  final qty = shopifyReviewLineItemQty(item);
                  final price = shopifyReviewLineItemPrice(item);
                  final imageUrl = shopifyReviewLineItemImageUrl(item) ?? '';
                  final extra = shopifyReviewLineItemExtra(item);
                  final lineCard = shopifyReviewResolvedLineCardMessage(
                    item: item,
                    orderCardMessage: review.cardMessage,
                    items: lineItems,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrderItemProductThumb(
                          productRef: null,
                          imageUrl: imageUrl,
                          title: title,
                          theme: FlutterFlowTheme.of(sheetContext),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: FlutterFlowTheme.of(sheetContext)
                                    .bodyMedium
                                    .override(fontWeight: FontWeight.w600),
                              ),
                              if (variant.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  variant,
                                  style: FlutterFlowTheme.of(sheetContext)
                                      .bodySmall
                                      .override(
                                        color: FlutterFlowTheme.of(sheetContext)
                                            .secondaryText,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Qty: $qty',
                                style: FlutterFlowTheme.of(sheetContext)
                                    .bodySmall,
                              ),
                              if (lineCard.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${tr(sheetContext, 'order.field.cardMessage')} $lineCard',
                                  style: FlutterFlowTheme.of(sheetContext)
                                      .bodySmall,
                                ),
                              ],
                              if (extra.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  extra,
                                  style: FlutterFlowTheme.of(sheetContext)
                                      .bodySmall
                                      .override(
                                        color: FlutterFlowTheme.of(sheetContext)
                                            .secondaryText,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          formatNumber(
                            price,
                            formatType: FormatType.decimal,
                            decimalType: DecimalType.automatic,
                            currency: r'$',
                          ),
                          style: FlutterFlowTheme.of(sheetContext)
                              .bodyMedium
                              .override(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
                if (lineItems.isEmpty)
                  Text(shopifyReviewProductSummary(review)),
                if (review.quarantineReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(review.quarantineReason),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmAction({
    required String titleKey,
    required String bodyKey,
    required String confirmKey,
    required Map<String, String> params,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(dialogContext, titleKey)),
        content: Text(tr(dialogContext, bodyKey, params: params)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, confirmKey)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmApprove({
    required String titleKey,
    required String bodyKey,
    required Map<String, String> params,
  }) {
    return _confirmAction(
      titleKey: titleKey,
      bodyKey: bodyKey,
      confirmKey: 'order.shopify.approve',
      params: params,
    );
  }

  Future<bool> _confirmDelete({
    required String titleKey,
    required String bodyKey,
    required Map<String, String> params,
  }) {
    return _confirmAction(
      titleKey: titleKey,
      bodyKey: bodyKey,
      confirmKey: 'order.shopify.delete',
      params: params,
    );
  }

  Future<void> _approveIds(List<String> reviewIds, {String? singleId}) async {
    if (reviewIds.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _approvingReviewId = singleId;
    });
    try {
      final result = await approveShopifyReviews(reviewIds: reviewIds);
      if (!mounted) {
        return;
      }
      if (result.hasFailures) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'order.shopify.approvePartial',
                params: {
                  'approved': '${result.approvedCount + result.alreadyApprovedCount}',
                  'failed': '${result.failed.length}',
                },
              ),
            ),
            backgroundColor: FlutterFlowTheme.of(context).tertiary,
          ),
        );
        setState(() {
          for (final item in [...result.approved, ...result.alreadyApproved]) {
            _selectedIds.remove(item.reviewId);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewIds.length == 1
                  ? tr(context, 'order.shopify.approveSuccess')
                  : tr(
                      context,
                      'order.shopify.approveBulkSuccess',
                      params: {
                        'count': '${result.approvedCount + result.alreadyApprovedCount}',
                      },
                    ),
            ),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );
        setState(() {
          for (final id in reviewIds) {
            _selectedIds.remove(id);
          }
        });
      }
      await _loadReviews();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.shopify.approveFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _approvingReviewId = null;
        });
      }
    }
  }

  Future<void> _approveOne(ShopifyReviewsRecord review) async {
    final confirmed = await _confirmApprove(
      titleKey: 'order.shopify.approveTitle',
      bodyKey: 'order.shopify.approveBody',
      params: {'shopify': shopifyReviewShopifyLabel(review)},
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _approveIds([review.reference.id], singleId: review.reference.id);
  }

  Future<void> _approveSelected() async {
    final selected = _visibleSelectable
        .where((review) => _selectedIds.contains(review.reference.id))
        .map((review) => review.reference.id)
        .toList(growable: false);
    if (selected.isEmpty) {
      return;
    }
    final confirmed = await _confirmApprove(
      titleKey: 'order.shopify.approveBulkTitle',
      bodyKey: 'order.shopify.approveBulkBody',
      params: {'count': '${selected.length}'},
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _approveIds(selected);
  }

  Future<void> _deleteIds(List<String> reviewIds, {String? singleId}) async {
    if (reviewIds.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _approvingReviewId = singleId;
    });
    try {
      final result = await deleteShopifyReviews(reviewIds: reviewIds);
      if (!mounted) {
        return;
      }
      if (result.hasFailures) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'order.shopify.deletePartial',
                params: {
                  'deleted': '${result.deletedCount}',
                  'failed': '${result.failed.length}',
                },
              ),
            ),
            backgroundColor: FlutterFlowTheme.of(context).tertiary,
          ),
        );
        setState(() {
          for (final item in result.deleted) {
            _selectedIds.remove(item.reviewId);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewIds.length == 1
                  ? tr(context, 'order.shopify.deleteSuccess')
                  : tr(
                      context,
                      'order.shopify.deleteBulkSuccess',
                      params: {'count': '${result.deletedCount}'},
                    ),
            ),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );
        setState(() {
          for (final id in reviewIds) {
            _selectedIds.remove(id);
          }
        });
      }
      await _loadReviews();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.shopify.deleteFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _approvingReviewId = null;
        });
      }
    }
  }

  Future<void> _deleteOne(ShopifyReviewsRecord review) async {
    final confirmed = await _confirmDelete(
      titleKey: 'order.shopify.deleteTitle',
      bodyKey: 'order.shopify.deleteBody',
      params: {'shopify': shopifyReviewShopifyLabel(review)},
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _deleteIds([review.reference.id], singleId: review.reference.id);
  }

  Future<void> _deleteSelected() async {
    final selected = _visibleSelectable
        .where((review) => _selectedIds.contains(review.reference.id))
        .map((review) => review.reference.id)
        .toList(growable: false);
    if (selected.isEmpty) {
      return;
    }
    final confirmed = await _confirmDelete(
      titleKey: 'order.shopify.deleteBulkTitle',
      bodyKey: 'order.shopify.deleteBulkBody',
      params: {'count': '${selected.length}'},
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _deleteIds(selected);
  }

  String _statusLabel(BuildContext context, ShopifyReviewsRecord review) {
    switch (review.reviewStatus) {
      case ShopifyReviewStatus.approved:
        return tr(context, 'order.shopify.status.approved');
      case ShopifyReviewStatus.quarantined:
        return tr(context, 'order.shopify.status.quarantined');
      case ShopifyReviewStatus.rejected:
        return tr(context, 'order.shopify.status.rejected');
      default:
        return tr(context, 'order.shopify.status.pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final canApprove = canApproveShopifyReviews(role);
    final visible = _visibleReviews;
    final pendingCount = _allReviews.where(isShopifyReviewPending).length;
    final selectedVisibleCount = _visibleSelectable
        .where((review) => _selectedIds.contains(review.reference.id))
        .length;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30,
            borderWidth: 1,
            buttonSize: 60,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            tr(context, 'order.shopify.title'),
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              tooltip: tr(context, 'common.refresh'),
              onPressed: _loading || _busy ? null : _loadReviews,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
            const HomeNavIconButton.onPrimary(),
          ],
          centerTitle: false,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error == '__no_permission__'
                ? _CenteredMessage(tr(context, 'order.shopify.noPermission'))
                : _error != null
                    ? _CenteredMessage(
                        tr(context, 'order.shopify.loadFailed'),
                        actionLabel: tr(context, 'common.retry'),
                        onAction: _loadReviews,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText:
                                    tr(context, 'order.shopify.searchHint'),
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: theme.secondaryBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilterChip(
                                  label: Text(
                                    tr(
                                      context,
                                      'order.shopify.filterPending',
                                      params: {'count': '$pendingCount'},
                                    ),
                                  ),
                                  selected: _pendingOnly,
                                  onSelected: (_) => setState(() {
                                    _pendingOnly = true;
                                    _selectedIds.clear();
                                  }),
                                ),
                                FilterChip(
                                  label: Text(
                                    tr(context, 'order.shopify.filterAll'),
                                  ),
                                  selected: !_pendingOnly,
                                  onSelected: (_) => setState(() {
                                    _pendingOnly = false;
                                    _selectedIds.clear();
                                  }),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              tr(
                                context,
                                'order.shopify.subtitle',
                                params: {'count': '${visible.length}'},
                              ),
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                          if (visible.isNotEmpty)
                            OrderListTableHeader(
                              selectAllValue: _selectAllValue(),
                              onSelectAllChanged:
                                  canApprove && _visibleSelectable.isNotEmpty
                                      ? _toggleSelectAll
                                      : null,
                            ),
                          Expanded(
                            child: visible.isEmpty
                                ? _CenteredMessage(
                                    tr(context, 'order.shopify.empty'),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: visible.length,
                                    itemBuilder: (context, index) {
                                      final review = visible[index];
                                      final pending =
                                          isShopifyReviewSelectable(review);
                                      return _ShopifyReviewRow(
                                        review: review,
                                        statusLabel:
                                            _statusLabel(context, review),
                                        checked: _selectedIds
                                            .contains(review.reference.id),
                                        canSelect: canApprove && pending,
                                        canApprove: canApprove && pending,
                                        approving: _approvingReviewId ==
                                            review.reference.id,
                                        busy: _busy,
                                        onCheckedChanged: (value) =>
                                            _toggleSelected(review, value),
                                        onOpen: () => isShopifyReviewApproved(
                                          review,
                                        )
                                            ? _openOfficialOrder(review)
                                            : _showDetails(review),
                                        onApprove: () => _approveOne(review),
                                        onDelete: () => _deleteOne(review),
                                      );
                                    },
                                  ),
                          ),
                          if (canApprove && selectedVisibleCount > 0)
                            _ShopifyReviewActionBar(
                              selectedCount: selectedVisibleCount,
                              busy: _busy,
                              onClear: () =>
                                  setState(_selectedIds.clear),
                              onApproveSelected: _approveSelected,
                              onDeleteSelected: _deleteSelected,
                            ),
                        ],
                      ),
      ),
    );
  }
}

class _ShopifyReviewRow extends StatelessWidget {
  const _ShopifyReviewRow({
    required this.review,
    required this.statusLabel,
    required this.checked,
    required this.canSelect,
    required this.canApprove,
    required this.approving,
    required this.busy,
    required this.onCheckedChanged,
    required this.onOpen,
    required this.onApprove,
    required this.onDelete,
  });

  final ShopifyReviewsRecord review;
  final String statusLabel;
  final bool checked;
  final bool canSelect;
  final bool canApprove;
  final bool approving;
  final bool busy;
  final ValueChanged<bool?> onCheckedChanged;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final paid = shopifyReviewLooksPaid(review);
    final voided = shopifyReviewLooksVoided(review);
    final customer = shopifyReviewCustomer(review);
    final recipient = shopifyReviewRecipient(review);

    return Material(
      color: theme.secondaryBackground,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.alternate, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: canSelect ? checked : false,
                onChanged: canSelect && !busy ? onCheckedChanged : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: theme.primary,
                checkColor: theme.info,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shopifyReviewShopifyLabel(review),
                            style: theme.titleMedium.override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: theme.bodySmall.override(
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(customer, style: theme.bodyMedium),
                    if (recipient != customer) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${tr(context, 'order.col.recipient')}: $recipient',
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                    if (shopifyReviewDeliveryAddress(review).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        shopifyReviewDeliveryAddress(review),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                    ] else if (shopifyReviewBillingAddress(review).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        shopifyReviewBillingAddress(review),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      shopifyReviewProductSummary(review),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    if (shopifyReviewLineItemImageUrls(review).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final item in shopifyReviewLineItemMaps(review))
                            OrderItemProductThumb(
                              productRef: null,
                              imageUrl:
                                  shopifyReviewLineItemImageUrl(item) ?? '',
                              title: shopifyReviewLineItemTitle(item),
                              theme: theme,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          label: review.orderType.isNotEmpty
                              ? review.orderType
                              : '-',
                        ),
                        _MetaChip(
                          label: formatNumber(
                            review.totalPrice,
                            formatType: FormatType.decimal,
                            decimalType: DecimalType.automatic,
                            currency: r'$',
                          ),
                        ),
                        _MetaChip(
                          label: _financialStatusLabel(context, review),
                          emphasize: paid,
                          attention: voided,
                        ),
                        if (shopifyReviewScheduleLabel(review).isNotEmpty)
                          _MetaChip(
                            label: shopifyReviewScheduleLabel(review),
                          ),
                        if (review.cardMessage.trim().isNotEmpty)
                          _MetaChip(
                            label: tr(context, 'order.field.cardMessage'),
                          ),
                        if (review.receivedAt != null)
                          _MetaChip(
                            label: dateTimeFormat(
                              'MMM d, HH:mm',
                              review.receivedAt,
                              locale: Localizations.localeOf(context)
                                  .languageCode,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: busy ? null : onOpen,
                          child: Text(
                            isShopifyReviewApproved(review)
                                ? tr(context, 'order.shopify.openOfficial')
                                : tr(context, 'order.shopify.open'),
                          ),
                        ),
                        const Spacer(),
                        if (canApprove) ...[
                          OutlinedButton(
                            onPressed: busy ? null : onDelete,
                            child: Text(tr(context, 'order.shopify.delete')),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: busy ? null : onApprove,
                            child: approving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(tr(context, 'order.shopify.approve')),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopifyReviewActionBar extends StatelessWidget {
  const _ShopifyReviewActionBar({
    required this.selectedCount,
    required this.busy,
    required this.onClear,
    required this.onApproveSelected,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final bool busy;
  final VoidCallback onClear;
  final VoidCallback onApproveSelected;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: busy ? null : onClear,
            child: Text(tr(context, 'order.shopify.clearSelection')),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: busy ? null : onDeleteSelected,
                child: Text(
                  tr(
                    context,
                    'order.shopify.deleteSelected',
                    params: {'count': '$selectedCount'},
                  ),
                ),
              ),
              FilledButton(
                onPressed: busy ? null : onApproveSelected,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        tr(
                          context,
                          'order.shopify.approveSelected',
                          params: {'count': '$selectedCount'},
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.emphasize = false,
    this.attention = false,
  });

  final String label;
  final bool emphasize;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = attention
        ? theme.tertiary
        : emphasize
            ? theme.secondary
            : theme.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: attention
            ? theme.tertiary.withValues(alpha: 0.15)
            : emphasize
                ? theme.secondary.withValues(alpha: 0.15)
                : theme.primaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.labelSmall.override(
          color: color,
          fontWeight: (emphasize || attention) ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(
    this.message, {
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.bodyLarge.override(color: theme.secondaryText),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
