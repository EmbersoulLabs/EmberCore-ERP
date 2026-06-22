import 'package:flutter/material.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/components/ember_app_shell.dart';
import '/components/ember_section_card.dart';
import '/components/manage_role_permissions_panel.dart';
import '/theme/ember_navigation.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RolePermissionsPageWidget extends StatefulWidget {
  const RolePermissionsPageWidget({super.key});

  static String routeName = 'RolePermissionsPage';
  static String routePath = '/rolePermissions';

  @override
  State<RolePermissionsPageWidget> createState() =>
      _RolePermissionsPageWidgetState();
}

class _RolePermissionsPageWidgetState extends State<RolePermissionsPageWidget> {
  @override
  Widget build(BuildContext context) {
    final canManage = canManageRolePermissions(currentViewerRole());

    return EmberAppShell(
      selectedPath: RolePermissionsPageWidget.routePath,
      title: tr(context, 'admin.rolePermissions.title'),
      subtitle: tr(context, 'admin.rolePermissions.intro'),
      showBackButton: true,
      navGroups: buildEmberNavGroups(context),
      body: !canManage
          ? Center(
              child: Text(
                tr(context, 'admin.rolePermissions.noAccess'),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EmberSectionCard(
                  title: tr(context, 'admin.rolePermissions.title'),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height - 220,
                    child: ManageRolePermissionsPanel(
                      onSavingChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
