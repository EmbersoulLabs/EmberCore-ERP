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
        ),
        item(
          labelKey: 'nav.orders',
          icon: Icons.receipt_long_outlined,
          routePath: OrderlistWidget.routePath,
          routeName: OrderlistWidget.routeName,
        ),
        item(
          labelKey: 'nav.pos',
          icon: Icons.point_of_sale_outlined,
          routePath: SalesDashBoardWidget.routePath,
          onTap: onCreateOrder,
        ),
        item(
          labelKey: 'nav.customers',
          icon: Icons.people_outline,
          routePath: CustomerListPageWidget.routePath,
          routeName: CustomerListPageWidget.routeName,
        ),
        item(
          labelKey: 'nav.delivery',
          icon: Icons.local_shipping_outlined,
          routePath: DriverAssignmentsPageWidget.routePath,
          routeName: DriverAssignmentsPageWidget.routeName,
          visible: canAssignDriver(role),
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

String emberNavLabel(BuildContext context, String key) => tr(context, key);
