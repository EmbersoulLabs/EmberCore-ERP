import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/record_edit_permissions.dart';
import '/auth/role_helpers.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/order_tracking_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/backend/reprint_receipt_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/backend/staff_notice_helpers.dart';
import '/components/assign_driver_sheet.dart';
import '/components/update_order_status_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

bool _isRetailOrder(OrdersRecord order) {
  final type =
      order.orderType.isNotEmpty ? order.orderType : order.pickupDelivery;
  return type == 'Retail';
}

/// Compact order-detail actions: one primary button + overflow menu.
class OrderDetailActionsPanel extends StatelessWidget {
  const OrderDetailActionsPanel({
    super.key,
    required this.order,
    required this.orderRef,
    this.onActionComplete,
  });

  final OrdersRecord order;
  final DocumentReference orderRef;
  final VoidCallback? onActionComplete;

  bool get _canUpdateStatus =>
      canUpdateOrderStatus(AppStateNotifier.instance.userRole);

  bool get _canAssign => canAssignDriver(AppStateNotifier.instance.userRole);

  bool get _canPrint => canPrintCashInvoice(AppStateNotifier.instance.userRole);

  bool get _isSuperAdmin => isSuperAdminRole(AppStateNotifier.instance.userRole);

  bool get _showDeliveryFlow => !_isRetailOrder(order);

  bool get _canSendTrackingLink => isTrackableCustomerOrder(order);

  Future<void> _showMoreActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tr(sheetContext, 'order.action.moreActions'),
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: EmberBrand.navy,
                    ),
                  ),
                ),
              ),
              if (_canAssign)
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(tr(sheetContext, 'order.action.assignDriver')),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showAssignDriverSheet(
                      context,
                      orderRef: orderRef,
                      order: order,
                    );
                  },
                ),
              if (_showDeliveryFlow)
                ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: Text(tr(sheetContext, 'order.action.deliveryOrder')),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await runDeliveryOrderFlow(context, orderRef);
                    onActionComplete?.call();
                  },
                ),
              if (_canPrint)
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(tr(sheetContext, 'order.action.printReceipt')),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await promptAndReprintOrderReceipt(context, orderRef, order);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu_outlined),
                title: Text(tr(sheetContext, 'order.action.productionMenu')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openProductionMenuPreview(context, orderRef);
                },
              ),
              if (isOrderWhatsAppConfirmationEnabled)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(tr(sheetContext, 'order.action.whatsappCustomer')),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await launchOrderConfirmationWhatsApp(
                      context: context,
                      order: order,
                    );
                  },
                ),
              if (_canSendTrackingLink)
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: Text(tr(sheetContext, 'track.action.sendTrackingLink')),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await launchOrderTrackingWhatsApp(
                      context: context,
                      order: order,
                    );
                  },
                ),
              if (_isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.local_florist_outlined),
                  title: Text(
                    tr(sheetContext, 'order.action.sendPurchaseReminder'),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _sendPurchaseReminder(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendPurchaseReminder(BuildContext context) async {
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

  Future<void> _openUpdateStatus(BuildContext context) async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: UpdateOrderStatusWidget(orderRef: orderRef),
          ),
        );
      },
    );
    onActionComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canUpdateStatus) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => _showMoreActions(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: EmberBrand.navy,
              side: const BorderSide(color: EmberBrand.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
              ),
            ),
            child: Text(tr(context, 'order.action.moreActions')),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: EmberBrand.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
                  ),
                ),
                onPressed: () => _openUpdateStatus(context),
                child: Text(tr(context, 'order.action.updateStatus')),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => _showMoreActions(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EmberBrand.navy,
                  side: const BorderSide(color: EmberBrand.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.more_horiz_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
