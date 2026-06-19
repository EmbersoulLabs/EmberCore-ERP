import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/components/home_nav_button.dart';
import '/components/manage_tenant_platform_config_panel.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class IndustrySettingsPageWidget extends StatefulWidget {
  const IndustrySettingsPageWidget({super.key});

  static String routeName = 'IndustrySettingsPage';
  static String routePath = '/industrySettings';

  @override
  State<IndustrySettingsPageWidget> createState() =>
      _IndustrySettingsPageWidgetState();
}

class _IndustrySettingsPageWidgetState extends State<IndustrySettingsPageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSuperAdmin = isSuperAdminRole(currentViewerRole());

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr(context, 'admin.industrySettings.title'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: !isSuperAdmin
          ? Center(child: Text(tr(context, 'admin.industrySettings.noAccess')))
          : const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ManageTenantPlatformConfigPanel(),
              ),
            ),
    );
  }
}
