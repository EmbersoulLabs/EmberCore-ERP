import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/components/language_picker_button.dart';
import '/components/staff_notice_app_bar_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/theme/ember_brand.dart';
import '/theme/ember_navigation.dart';

/// Premium SaaS shell: navy sidebar on desktop, compact app bar on mobile.
class EmberAppShell extends StatelessWidget {
  const EmberAppShell({
    super.key,
    required this.selectedPath,
    required this.body,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.extraActions = const [],
    this.onMenuPressed,
    this.navGroups,
  });

  final String selectedPath;
  final Widget body;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget> extraActions;
  final VoidCallback? onMenuPressed;
  final List<EmberNavGroup>? navGroups;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useSidebar = width >= EmberBrand.sidebarBreakpoint;

    if (!useSidebar) {
      return Scaffold(
        backgroundColor: EmberBrand.background,
        appBar: _MobileAppBar(
          title: title,
          subtitle: subtitle,
          showBackButton: showBackButton,
          onMenuPressed: onMenuPressed,
          extraActions: extraActions,
        ),
        body: body,
      );
    }

    final groups = navGroups ?? buildEmberNavGroups(context);

    return Scaffold(
      backgroundColor: EmberBrand.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmberSidebar(
            selectedPath: selectedPath,
            groups: groups,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopHeader(
                  title: title,
                  subtitle: subtitle,
                  extraActions: extraActions,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmberSidebar extends StatelessWidget {
  const EmberSidebar({
    super.key,
    required this.selectedPath,
    required this.groups,
  });

  final String selectedPath;
  final List<EmberNavGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: EmberBrand.sidebarWidth,
      color: EmberBrand.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kProductName,
                    style: GoogleFonts.interTight(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'brand.productSubtitle'),
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x33FFFFFF)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                      child: Text(
                        emberNavLabel(context, group.titleKey).toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    for (final item in group.items.where((i) => i.visible))
                      _SidebarTile(
                        item: item,
                        selected: _isSelected(selectedPath, item),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x33FFFFFF)),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.logout,
                color: Colors.white.withValues(alpha: 0.75),
                size: 20,
              ),
              title: Text(
                tr(context, 'dashboard.action.logout'),
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              onTap: () => context.pushNamed(LoginPageWidget.routeName),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                kLegalEntityName,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(String path, EmberNavItem item) {
    if (item.routePath == path) {
      return true;
    }
    if (path == '/' && item.routePath == SalesDashBoardWidget.routePath) {
      return true;
    }
    return false;
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
  });

  final EmberNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? EmberBrand.electricBlue.withValues(alpha: 0.18) : null;
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.78);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: bg ?? Colors.transparent,
        borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
          onTap: () {
            if (item.onTap != null) {
              item.onTap!();
              return;
            }
            if (item.routeName != null) {
              context.pushNamed(item.routeName!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    emberNavLabel(context, item.labelKey),
                    style: GoogleFonts.inter(
                      color: fg,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: EmberBrand.electricBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    this.title,
    this.subtitle,
    this.extraActions = const [],
  });

  final String? title;
  final String? subtitle;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 16),
      decoration: const BoxDecoration(
        color: EmberBrand.card,
        border: Border(bottom: BorderSide(color: EmberBrand.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: GoogleFonts.interTight(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: EmberBrand.navy,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: EmberBrand.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...extraActions,
          const StaffNoticeAppBarButton(),
          const LanguagePickerAppBarButton(),
        ],
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileAppBar({
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onMenuPressed,
    this.extraActions = const [],
  });

  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final List<Widget> extraActions;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EmberBrand.navy,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? kProductName,
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        if (onMenuPressed != null)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: onMenuPressed,
          ),
        ...extraActions,
        const StaffNoticeAppBarButton.onPrimary(),
        const LanguagePickerAppBarButton(),
      ],
    );
  }
}
