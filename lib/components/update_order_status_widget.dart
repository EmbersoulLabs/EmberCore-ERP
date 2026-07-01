import '/auth/viewer_role_helpers.dart';
import '/auth/frozen_order_permissions.dart';
import '/backend/backend.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/cash_payment_helpers.dart';
import '/components/outstanding_balance_dialog.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_status_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'update_order_status_model.dart';
export 'update_order_status_model.dart';

class _StatusOption {
  const _StatusOption({
    required this.status,
    required this.labelKey,
    required this.icon,
  });

  final OrderStatus status;
  final String labelKey;
  final IconData icon;
}

const _statusOptions = [
  _StatusOption(
    status: OrderStatus.processing,
    labelKey: 'order.status.processing',
    icon: Icons.autorenew_rounded,
  ),
  _StatusOption(
    status: OrderStatus.ready_to_delivery,
    labelKey: 'order.status.readyToShip',
    icon: Icons.inventory_2_outlined,
  ),
  _StatusOption(
    status: OrderStatus.out_of_delivery,
    labelKey: 'order.status.outOfDelivery',
    icon: Icons.local_shipping_outlined,
  ),
  _StatusOption(
    status: OrderStatus.completed,
    labelKey: 'order.status.completed',
    icon: Icons.check_circle_outline_rounded,
  ),
  _StatusOption(
    status: OrderStatus.cancelled,
    labelKey: 'order.status.cancelled',
    icon: Icons.block_rounded,
  ),
];

class UpdateOrderStatusWidget extends StatefulWidget {
  const UpdateOrderStatusWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  @override
  State<UpdateOrderStatusWidget> createState() =>
      _UpdateOrderStatusWidgetState();
}

class _UpdateOrderStatusWidgetState extends State<UpdateOrderStatusWidget> {
  late UpdateOrderStatusModel _model;
  bool _applying = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UpdateOrderStatusModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  Future<void> _applyStatus(OrderStatus status) async {
    if (_applying || widget.orderRef == null) {
      return;
    }
    setState(() => _applying = true);
    try {
      final order = await OrdersRecord.getDocumentOnce(widget.orderRef!);
      if (status == OrderStatus.cancelled &&
          !canCancelOrVoidFrozenOrder(currentViewerRole(), order)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(context, 'order.inventory.frozenCancelDenied'),
              ),
            ),
          );
        }
        return;
      }

      if (status == OrderStatus.ready_to_delivery ||
          status == OrderStatus.completed) {
        final saleTotal = await loadOrderSaleTotal(widget.orderRef!);
        if (mounted) {
          await showBalanceDueReminderDialog(
            context,
            order: order,
            targetStatus: status,
            saleTotal: saleTotal,
          );
        }
      }

      await updateOrderStatus(widget.orderRef!, status);
      await auditLogOrderStatusChangeByRef(widget.orderRef!, status);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  Widget _buildStatusTile(_StatusOption option) {
    final accent = emberOrderStatusColor(option.status);
    final background = emberOrderStatusBackground(option.status);
    final isDestructive = option.status == OrderStatus.cancelled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
        child: InkWell(
          onTap: _applying ? null : () => _applyStatus(option.status),
          borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
              border: Border.all(
                color: accent.withValues(alpha: isDestructive ? 0.35 : 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(option.icon, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    tr(context, option.labelKey),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? EmberBrand.error : EmberBrand.navy,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: EmberBrand.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: EmberBrand.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EmberBrand.radiusLg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EmberBrand.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          _applying ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: EmberBrand.navy,
                      tooltip: tr(context, 'common.back'),
                    ),
                    Expanded(
                      child: Text(
                        tr(context, 'order.statusSheet.title'),
                        style: GoogleFonts.interTight(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: EmberBrand.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  shrinkWrap: true,
                  children: [
                    for (final option in _statusOptions)
                      _buildStatusTile(option),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed:
                            _applying ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(tr(context, 'common.back')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EmberBrand.navy,
                          side: const BorderSide(color: EmberBrand.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(EmberBrand.radiusMd),
                          ),
                        ),
                      ),
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
