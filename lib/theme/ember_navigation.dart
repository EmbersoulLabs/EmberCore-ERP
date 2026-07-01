import 'package:flutter/material.dart';

import '/auth/role_helpers.dart';
import '/backend/whatsapp_order_import_service.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/l10n/tr.dart';
import '/platform/platform_module.dart';
import '/platform/platform_labels.dart';

class EmberNavItem {
  const EmberNavItem({
    required this.labelKey,
    required this.icon,
    required this.routePath,
    this.routeName,
    this.onTap,
    this.visible = true,
  });

  final String labelKey;
  final IconData icon;
  final String routePath;
  final String? routeName;
  final VoidCallback? onTap;
  final bool visible;
}

class EmberNavGroup {
  const EmberNavGroup({
    required this.titleKey,
    required this.items,
  });

  final String titleKey;
  final List<EmberNavItem> items;
}

List<EmberNavGroup> buildEmberNavGroups(
  BuildContext context, {
  VoidCallback? onOrderImport,
  VoidCallback? onCreateOrder,
}) {
  final role = AppStateNotifier.instance.userRole;

  EmberNavItem item({
    required String labelKey,
    required IconData icon,
    required String routePath,
    String? routeName,
    VoidCallback? onTap,
    bool visible = true,
  }) =>
      EmberNavItem(
        labelKey: labelKey,
        icon: icon,
        routePath: routePath,
        routeName: routeName,
        onTap: onTap,
        visible: visible,
      );

  return [
    EmberNavGroup(
      titleKey: 'nav.group.operations',
      items: [
        item(
          labelKey: 'nav.dashboard',
          icon: Icons.dashboard_outlined,
          routePath: SalesDashBoardWidget.routePath,
          routeName: SalesDashBoardWidget.routeName,
          visible: platformModuleEnabled(PlatformModule.orders) ||
              platformModuleEnabled(PlatformModule.reports),
        ),
        item(
          labelKey: 'nav.orders',
          icon: Icons.receipt_long_outlined,
          routePath: OrderlistWidget.routePath,
          routeName: OrderlistWidget.routeName,
          visible: platformModuleEnabled(PlatformModule.orders),
        ),
        item(
          labelKey: 'nav.pos',
          icon: Icons.point_of_sale_outlined,
          routePath: SalesDashBoardWidget.routePath,
          onTap: onCreateOrder,
          visible: platformModuleEnabled(PlatformModule.pos),
        ),
        item(
          labelKey: 'nav.customers',
          icon: Icons.people_outline,
          routePath: CustomerListPageWidget.routePath,
          routeName: CustomerListPageWidget.routeName,
          visible: platformModuleEnabled(PlatformModule.customers),
        ),
        item(
          labelKey: 'nav.delivery',
          icon: Icons.local_shipping_outlined,
          routePath: DriverAssignmentsPageWidget.routePath,
          routeName: DriverAssignmentsPageWidget.routeName,
          visible: platformModuleEnabled(PlatformModule.drivers) &&
              canAssignDriver(role),
        ),
      ],
    ),
    EmberNavGroup(
      titleKey: 'nav.group.management',
      items: [
        item(
          labelKey: 'nav.inventory',
          icon: Icons.inventory_2_outlined,
          routePath: ProductlistWidget.routePath,
          routeName: ProductlistWidget.routeName,
          visible: platformModuleEnabled(PlatformModule.products),
        ),
        item(
          labelKey: 'nav.staff',
          icon: Icons.group_outlined,
          routePath: UserListPageWidget.routePath,
          routeName: UserListPageWidget.routeName,
          visible: canViewUserList(role),
        ),
        item(
          labelKey: 'nav.rolesPermissions',
          icon: Icons.admin_panel_settings_outlined,
          routePath: RolePermissionsPageWidget.routePath,
          routeName: RolePermissionsPageWidget.routeName,
          visible: canManageRolePermissions(role),
        ),
        item(
          labelKey: 'nav.reports',
          icon: Icons.assessment_outlined,
          routePath: SalesReportPageWidget.routePath,
          routeName: SalesReportPageWidget.routeName,
          visible: platformModuleEnabled(PlatformModule.reports),
        ),
      ],
    ),
    EmberNavGroup(
      titleKey: 'nav.group.integrations',
      items: [
        item(
          labelKey: 'nav.orderImport',
          icon: Icons.content_paste_go_outlined,
          routePath: SalesDashBoardWidget.routePath,
          onTap: onOrderImport,
          visible: isWhatsAppOrderImportEnabled &&
              platformModuleEnabled(PlatformModule.whatsappImport),
        ),
        item(
          labelKey: 'nav.businessSettings',
          icon: Icons.settings_outlined,
          routePath: CompanySettingPageWidget.routePath,
          routeName: CompanySettingPageWidget.routeName,
          visible: canEditCompanyProfile(role),
        ),
        item(
          labelKey: 'nav.billing',
          icon: Icons.credit_card_outlined,
          routePath: BillingPageWidget.routePath,
          routeName: BillingPageWidget.routeName,
          visible: canManageBilling(role),
        ),
        item(
          labelKey: 'nav.industrySettings',
          icon: Icons.tune,
          routePath: IndustrySettingsPageWidget.routePath,
          routeName: IndustrySettingsPageWidget.routeName,
          visible: isSuperAdminRole(role),
        ),
      ],
    ),
  ];
}

String emberNavLabel(BuildContext context, String key) {
  if (key == 'nav.delivery') {
    return platformDriverRoleLabel(context);
  }
  return tr(context, key);
}
