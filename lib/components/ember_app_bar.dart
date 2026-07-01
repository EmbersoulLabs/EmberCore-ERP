import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/components/ember_brand_logo.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Narrow phones — tighter app bar icons and title typography.
bool emberCompactAppBar(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 480;

/// Icon size for primary / navy app bars.
double emberAppBarIconSize(BuildContext context) =>
    emberCompactAppBar(context) ? 20 : 22;

/// Minimum tap target for app bar icon buttons.
double emberAppBarIconButtonSize(BuildContext context) =>
    emberCompactAppBar(context) ? 36 : 44;

/// Compact [IconButton] for crowded mobile app bars.
class EmberAppBarIconButton extends StatelessWidget {
  const EmberAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.onPrimary = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final compact = emberCompactAppBar(context);
    final size = emberAppBarIconButtonSize(context);
    final iconColor = color ??
        (onPrimary ? Colors.white : FlutterFlowTheme.of(context).primaryText);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      icon: Icon(icon, size: emberAppBarIconSize(context), color: iconColor),
    );
  }
}

/// Standard navy/primary app bar for admin and detail pages.
class EmberPrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EmberPrimaryAppBar({
    super.key,
    this.title,
    this.onBack,
    this.actions = const [],
    this.backgroundColor,
    this.centerTitle,
    this.useBrandLogo = false,
  });

  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Color? backgroundColor;
  final bool? centerTitle;
  final bool useBrandLogo;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final compact = emberCompactAppBar(context);
    final theme = FlutterFlowTheme.of(context);
    final shouldCenter = centerTitle ?? !compact;

    return AppBar(
      backgroundColor: backgroundColor ?? theme.primary,
      elevation: 0,
      toolbarHeight: kToolbarHeight,
      centerTitle: shouldCenter,
      automaticallyImplyLeading: false,
      leadingWidth: compact ? 40 : 56,
      titleSpacing: compact ? 0 : NavigationToolbar.kMiddleSpacing,
      leading: onBack == null
          ? null
          : EmberAppBarIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              onPrimary: true,
            ),
      title: useBrandLogo
          ? EmberAppBarBrandTitle(
              pageTitle: title,
              showBackButton: onBack != null,
              titleStyle: GoogleFonts.interTight(
                color: Colors.white,
                fontSize: compact ? 15 : 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            )
          : Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.interTight(
                color: Colors.white,
                fontSize: compact ? 15 : 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
      actions: [
        ...actions,
        SizedBox(width: compact ? 4 : 8),
      ],
    );
  }
}

/// Title style for [EmberAppShell] mobile app bar.
TextStyle emberMobileShellTitleStyle(BuildContext context) {
  return GoogleFonts.interTight(
    color: Colors.white,
    fontSize: emberCompactAppBar(context) ? 15 : 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
}

TextStyle emberMobileShellSubtitleStyle(BuildContext context) {
  return GoogleFonts.inter(
    color: Colors.white70,
    fontSize: emberCompactAppBar(context) ? 11 : 12,
  );
}
