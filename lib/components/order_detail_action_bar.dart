import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/record_edit_permissions.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/cash_payment_helpers.dart';
import '/backend/order_ready_by_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/components/assign_driver_sheet.dart';
import '/components/assign_ready_by_sheet.dart';
import '/components/bulk_update_status_sheet.dart';
import '/components/edit_order_details_widget.dart';
import '/components/edit_order_products_widget.dart';
import '/components/outstanding_balance_dialog.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Future<void> openOrderDetailStatusSheet(
  BuildContext context, {
  required OrdersRecord order,
  required DocumentReference orderRef,
  VoidCallback? onOrderChanged,
}) async {
  await showOrderStatusPickerSheet(
    context,
    title: tr(context, 'order.statusSheet.title'),
    isPickup: isPickupOrderRecord(order),
    onApply: (status) async {
      if (status == OrderStatus.ready_to_delivery ||
          status == OrderStatus.completed) {
        final saleTotal = await loadOrderSaleTotal(orderRef);
        if (context.mounted) {
          await showBalanceDueReminderDialog(
            context,
            order: order,
            targetStatus: status,
            saleTotal: saleTotal,
          );
        }
      }

      await updateOrderStatus(orderRef, status);
    },
  );
  onOrderChanged?.call();
}

Future<void> sendOrderPurchaseReminder(
  BuildContext context, {
  required OrdersRecord order,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(tr(dialogContext, 'order.purchaseReminder.confirmTitle')),
        content: Text(tr(dialogContext, 'order.purchaseReminder.confirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, 'order.purchaseReminder.send')),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  try {
    final sent = await sendSpecialProcurementReminder(
      order: order,
      actorRole: AppStateNotifier.instance.userRole,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent > 0
              ? tr(
                  context,
                  'order.purchaseReminder.sent',
                  params: {'count': '$sent'},
                )
              : tr(context, 'order.purchaseReminder.noRecipients'),
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'order.purchaseReminder.failed')),
      ),
    );
  }
}

Future<void> cancelOrderFromDetail(
  BuildContext context, {
  required DocumentReference orderRef,
  VoidCallback? onOrderChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(tr(dialogContext, 'order.action.cancelOrder')),
        content: Text(tr(dialogContext, 'order.action.cancelOrderConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, 'order.action.cancelOrder')),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await updateOrderStatus(orderRef, OrderStatus.cancelled);
  onOrderChanged?.call();
}

class OrderDetailPrimaryActions extends StatelessWidget {
  const OrderDetailPrimaryActions({
    super.key,
    required this.order,
    required this.orderRef,
    required this.unpaid,
    required this.balanceDue,
    required this.saleTotal,
    this.onOrderChanged,
  });

  final OrdersRecord order;
  final DocumentReference orderRef;
  final bool unpaid;
  final double balanceDue;
  final double saleTotal;
  final VoidCallback? onOrderChanged;

  bool get _canPay {
    final role = AppStateNotifier.instance.userRole;
    return canPrintCashInvoice(role) || canUpdateOrderStatus(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final showStatus = canUpdateOrderStatus(role);
    final showPay = unpaid && _canPay;
    final showWhatsApp = isOrderWhatsAppConfirmationEnabled;

    if (!showStatus && !showPay && !showWhatsApp) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _outlineButton(
            context,
            label: tr(context, 'order.action.productionMenu'),
            onPressed: () => openProductionMenuPreview(context, orderRef),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showStatus)
          FFButtonWidget(
            onPressed: () => openOrderDetailStatusSheet(
              context,
              order: order,
              orderRef: orderRef,
              onOrderChanged: onOrderChanged,
            ),
            text: tr(context, 'order.action.updateStatus'),
            options: FFButtonOptions(
              height: 48,
              color: theme.primary,
              textStyle: theme.titleSmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: Colors.white,
              ),
              elevation: 0,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        if (showPay) ...[
          if (showStatus) const SizedBox(height: 8),
          FFButtonWidget(
            onPressed: () => showPayOutstandingBalanceDialog(
              context,
              orderRef: orderRef,
              order: order,
              saleTotal: saleTotal,
            ),
            text: tr(
              context,
              'order.action.pay',
              params: {'amount': formatCashMoney(balanceDue)},
            ),
            options: FFButtonOptions(
              height: 48,
              color: theme.secondaryBackground,
              textStyle: theme.titleSmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: theme.primaryText,
              ),
              elevation: 0,
              borderSide: BorderSide(color: theme.alternate),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _outlineButton(
                context,
                label: tr(context, 'order.action.productionMenu'),
                onPressed: () => openProductionMenuPreview(context, orderRef),
              ),
            ),
            if (showWhatsApp) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FFButtonWidget(
                  onPressed: () => launchOrderConfirmationWhatsApp(
                    context: context,
                    order: order,
                  ),
                  text: tr(context, 'order.action.whatsapp'),
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 16,
                  ),
                  options: FFButtonOptions(
                    height: 48,
                    color: const Color(0xFF25D366),
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: Colors.white,
                    ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _outlineButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return FFButtonWidget(
      onPressed: onPressed,
      text: label,
      options: FFButtonOptions(
        height: 48,
        color: theme.secondaryBackground,
        textStyle: theme.titleSmall.override(
          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
          color: theme.primaryText,
        ),
        elevation: 0,
        borderSide: BorderSide(color: theme.alternate),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

Future<void> showOrderDetailMoreSheet(
  BuildContext context, {
  required OrdersRecord order,
  required DocumentReference orderRef,
  VoidCallback? onOrderChanged,
}) async {
  final theme = FlutterFlowTheme.of(context);
  final role = AppStateNotifier.instance.userRole;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.secondaryBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                tr(sheetContext, 'order.action.more'),
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (canEditOrderRecord(role, order)) ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  tr(sheetContext, 'order.action.editCustomerAddress'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showEditOrderDetailsSheet(
                    context,
                    orderRef: orderRef,
                    order: order,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: Text(tr(sheetContext, 'order.action.editProducts')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showEditOrderProductsSheet(
                    context,
                    orderRef: orderRef,
                    order: order,
                  );
                },
              ),
            ],
            if (canAssignDriver(role))
              ListTile(
                leading: Icon(
                  order.hasAssignedDriver()
                      ? Icons.check_circle_outline
                      : Icons.local_shipping_outlined,
                ),
                title: Text(
                  order.hasAssignedDriver()
                      ? tr(sheetContext, 'order.driver.assigned')
                      : tr(sheetContext, 'order.action.assignDriver'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAssignDriverSheet(
                    context,
                    orderRef: orderRef,
                    order: order,
                  );
                },
              ),
            if (canAssignReadyBy(role))
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(tr(sheetContext, 'order.readyBy.title')),
                subtitle: Text(
                  order.hasReadyBy()
                      ? tr(sheetContext, 'order.readyBy.label')
                      : tr(sheetContext, 'order.readyBy.unassigned'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAssignReadyBySheet(context, order: order);
                },
              ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text(tr(sheetContext, 'order.action.deliveryOrder')),
              onTap: () {
                Navigator.pop(sheetContext);
                runDeliveryOrderFlow(context, orderRef);
              },
            ),
            if (isSuperAdminRole(role))
              ListTile(
                leading: const Icon(Icons.local_florist),
                title: Text(
                  tr(sheetContext, 'order.action.sendPurchaseReminder'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  sendOrderPurchaseReminder(context, order: order);
                },
              ),
            if (canUpdateOrderStatus(role) &&
                order.status != OrderStatus.cancelled)
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: theme.error),
                title: Text(
                  tr(sheetContext, 'order.action.cancelOrder'),
                  style: TextStyle(color: theme.error),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await cancelOrderFromDetail(
                    context,
                    orderRef: orderRef,
                    onOrderChanged: onOrderChanged,
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

class OrderDetailActionBar extends StatelessWidget {
  const OrderDetailActionBar({
    super.key,
    required this.order,
    required this.orderRef,
    this.onOrderChanged,
  });

  final OrdersRecord order;
  final DocumentReference orderRef;
  final VoidCallback? onOrderChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final actions = _buildActions(context, role);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'order.action.barTitle'),
            style: theme.labelMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _ActionBarTile(
                  icon: action.icon,
                  label: action.label,
                  color: action.color,
                  onTap: action.onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_OrderDetailAction> _buildActions(BuildContext context, UserRole? role) {
    final theme = FlutterFlowTheme.of(context);
    final actions = <_OrderDetailAction>[];

    void add({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) {
      actions.add(
        _OrderDetailAction(
          icon: icon,
          label: label,
          color: color,
          onTap: onTap,
        ),
      );
    }

    if (canEditOrderRecord(role, order)) {
      add(
        icon: Icons.person_outline,
        label: tr(context, 'order.action.editAddress'),
        color: theme.tertiary,
        onTap: () => showEditOrderDetailsSheet(
          context,
          orderRef: orderRef,
          order: order,
        ),
      );
      add(
        icon: Icons.shopping_bag_outlined,
        label: tr(context, 'order.action.editProducts'),
        color: theme.primary,
        onTap: () => showEditOrderProductsSheet(
          context,
          orderRef: orderRef,
          order: order,
        ),
      );
    }

    if (canAssignDriver(role)) {
      final assigned = order.hasAssignedDriver();
      add(
        icon: assigned
            ? Icons.check_circle_outline
            : Icons.local_shipping_outlined,
        label: assigned
            ? tr(context, 'order.driver.assigned')
            : tr(context, 'order.action.assignDriver'),
        color: assigned ? theme.success : theme.tertiary,
        onTap: () => showAssignDriverSheet(
          context,
          orderRef: orderRef,
          order: order,
        ),
      );
    }

    if (canAssignReadyBy(role)) {
      add(
        icon: Icons.badge_outlined,
        label: tr(context, 'order.readyBy.title'),
        color: order.hasReadyBy() ? theme.primary : theme.tertiary,
        onTap: () => showAssignReadyBySheet(context, order: order),
      );
    }

    add(
      icon: Icons.restaurant_menu,
      label: tr(context, 'order.action.productionMenu'),
      color: theme.tertiary,
      onTap: () => openProductionMenuPreview(context, orderRef),
    );

    if (isSuperAdminRole(role)) {
      add(
        icon: Icons.local_florist,
        label: tr(context, 'order.action.sendPurchaseReminder'),
        color: theme.warning,
        onTap: () => sendOrderPurchaseReminder(context, order: order),
      );
    }

    if (canUpdateOrderStatus(role)) {
      add(
        icon: Icons.check_circle_outline,
        label: tr(context, 'order.action.updateStatus'),
        color: theme.primary,
        onTap: () => openOrderDetailStatusSheet(
          context,
          order: order,
          orderRef: orderRef,
          onOrderChanged: onOrderChanged,
        ),
      );
    }

    add(
      icon: Icons.local_shipping,
      label: tr(context, 'order.action.deliveryOrder'),
      color: Colors.purple,
      onTap: () => runDeliveryOrderFlow(context, orderRef),
    );

    return actions;
  }

}

class _OrderDetailAction {
  const _OrderDetailAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _ActionBarTile extends StatelessWidget {
  const _ActionBarTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Material(
      color: theme.primaryBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
