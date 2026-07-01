import 'package:flutter/material.dart';

import '/app_branding.dart';

enum EmberBrandLogoVariant {
  horizontal,
  horizontalSm,
  stacked,
  icon,
  icon128,
}

/// EmberSoul Labs logo assets (transparent PNG).
class EmberBrandLogo extends StatelessWidget {
  const EmberBrandLogo({
    super.key,
    this.variant = EmberBrandLogoVariant.horizontalSm,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final EmberBrandLogoVariant variant;
  final double? width;
  final double? height;
  final BoxFit fit;

  String get _assetPath => switch (variant) {
        EmberBrandLogoVariant.horizontal => kEmberSoulLabsLogoHorizontal,
        EmberBrandLogoVariant.horizontalSm => kEmberSoulLabsLogoHorizontalSm,
        EmberBrandLogoVariant.stacked => kEmberSoulLabsLogoStacked,
        EmberBrandLogoVariant.icon => kEmberSoulLabsLogoIcon256,
        EmberBrandLogoVariant.icon128 => kEmberSoulLabsLogoIcon128,
      };

  /// Logo height for navy / primary app bars on phones vs desktop.
  static double appBarHeight(BuildContext context, {bool? compactOverride}) {
    final compact =
        compactOverride ?? MediaQuery.sizeOf(context).width < 480;
    return compact ? 26 : 32;
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: kLegalEntityName,
    );
  }
}

/// App bar title: brand logo on home screens, page title on detail screens.
class EmberAppBarBrandTitle extends StatelessWidget {
  const EmberAppBarBrandTitle({
    super.key,
    this.pageTitle,
    this.showBackButton = false,
    this.titleStyle,
  });

  final String? pageTitle;
  final bool showBackButton;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    final logoHeight = EmberBrandLogo.appBarHeight(context, compactOverride: compact);

    if (!showBackButton) {
      return Align(
        alignment: Alignment.centerLeft,
        child: EmberBrandLogo(
          variant: EmberBrandLogoVariant.horizontalSm,
          height: logoHeight,
        ),
      );
    }

    final title = pageTitle?.trim();
    if (title == null || title.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: EmberBrandLogo(
          variant: EmberBrandLogoVariant.horizontalSm,
          height: logoHeight,
        ),
      );
    }

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
  }
}
