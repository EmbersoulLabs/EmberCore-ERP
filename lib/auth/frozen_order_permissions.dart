import '/auth/role_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/auth/app_permissions.dart';
import '/auth/permission_service.dart';

/// Order inventory is locked after completion (or retail POS checkout).
bool isOrderInventoryFrozen(OrdersRecord order) =>
    order.inventoryFrozen || order.status == OrderStatus.completed;

/// Manager, admin, or platform superadmin may override frozen orders.
bool canOverrideFrozenOrder(UserRole? role) =>
    isManagerRole(role) ||
    isCompanyAdminRole(role) ||
    isSuperAdminRole(role);

bool canCancelOrVoidFrozenOrder(UserRole? role, OrdersRecord order) {
  if (!isOrderInventoryFrozen(order)) {
    return hasAppPermission(role, AppPermission.updateOrderStatus) ||
        hasAppPermission(role, AppPermission.deleteOrders);
  }
  return canOverrideFrozenOrder(role);
}

bool canEditFrozenOrderPricing(UserRole? role, OrdersRecord order) {
  if (!isOrderInventoryFrozen(order)) {
    return hasAppPermission(role, AppPermission.editOrderDetails);
  }
  return canOverrideFrozenOrder(role);
}
