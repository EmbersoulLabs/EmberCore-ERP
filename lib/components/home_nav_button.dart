import 'package:flutter/material.dart';

import '/auth/role_route_guard.dart';
import '/components/ember_app_bar.dart';
import '/components/language_picker_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

/// Navigates to the role home: Sales Dashboard (staff/admin) or My Deliveries (driver).
void navigateToHome(BuildContext context) {
  final role = AppStateNotifier.instance.userRole;
  context.go(defaultRoutePathForRole(role));
}

/// Home icon for app bars and custom headers.
class HomeNavIconButton extends StatelessWidget {
  const HomeNavIconButton({
    super.key,
    this.iconColor,
    this.fillColor,
  }) : _onPrimary = false;

  /// White icon on primary-colored bars (matches back button on summary pages).
  const HomeNavIconButton.onPrimary({super.key})
      : iconColor = Colors.white,
        fillColor = const Color(0x4DFFFFFF),
        _onPrimary = true;

  final Color? iconColor;
  final Color? fillColor;
  final bool _onPrimary;

  @override
  Widget build(BuildContext context) {
    if (_onPrimary) {
      return EmberAppBarIconButton(
        icon: Icons.home_rounded,
        onPressed: () => navigateToHome(context),
        tooltip: tr(context, 'common.home'),
        onPrimary: true,
      );
    }
    final compact = emberCompactAppBar(context);
    final size = compact ? 36.0 : 40.0;
    return FlutterFlowIconButton(
      borderRadius: 20.0,
      buttonSize: size,
      fillColor: fillColor,
      icon: Icon(
        Icons.home_outlined,
        color: iconColor ?? FlutterFlowTheme.of(context).primaryText,
        size: compact ? 20 : 22,
      ),
      onPressed: () => navigateToHome(context),
    );
  }
}

/// Text button variant for light app bars.
class HomeNavTextButton extends StatelessWidget {
  const HomeNavTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => navigateToHome(context),
      icon: Icon(
        Icons.home_outlined,
        size: 20.0,
        color: FlutterFlowTheme.of(context).primary,
      ),
      label: Text(
        tr(context, 'common.home'),
        style: FlutterFlowTheme.of(context).titleSmall.override(
              color: FlutterFlowTheme.of(context).primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Standard primary app bar actions: language picker + home.
class AppBarLanguageHomeActions extends StatelessWidget {
  const AppBarLanguageHomeActions({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = emberCompactAppBar(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LanguagePickerAppBarButton(compact: compact),
        HomeNavIconButton.onPrimary(),
      ],
    );
  }
}
