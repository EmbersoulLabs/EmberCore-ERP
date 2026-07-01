import 'package:flutter/material.dart';

import '/components/ember_app_bar.dart';
import '/components/home_nav_button.dart';
import '/components/manage_registration_requests_panel.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RegistrationRequestsPageWidget extends StatefulWidget {
  const RegistrationRequestsPageWidget({super.key});

  static String routeName = 'RegistrationRequestsPage';
  static String routePath = '/registrationRequests';

  @override
  State<RegistrationRequestsPageWidget> createState() =>
      _RegistrationRequestsPageWidgetState();
}

class _RegistrationRequestsPageWidgetState
    extends State<RegistrationRequestsPageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSuperAdmin = isSuperAdminRole(currentViewerRole());

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: EmberPrimaryAppBar(
        title: emberCompactAppBar(context)
            ? tr(context, 'admin.registrationRequests.titleShort')
            : tr(context, 'admin.registrationRequests.title'),
        onBack: () => context.pop(),
        backgroundColor: theme.primary,
        centerTitle: false,
        useBrandLogo: true,
        actions: const [HomeNavIconButton.onPrimary()],
      ),
      body: !isSuperAdmin
          ? Center(child: Text(tr(context, 'admin.registrationRequests.noAccess')))
          : const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ManageRegistrationRequestsPanel(),
              ),
            ),
    );
  }
}
