import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

/// A widget that centers content on tablets and desktops
/// while using full width on mobile devices
class ResponsiveCenterContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerOnMobile;

  const ResponsiveCenterContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = SizeConfig.isTablet || SizeConfig.isDesktop;
    final effectiveMaxWidth = maxWidth ?? 
      (SizeConfig.isDesktop ? 800.0 : SizeConfig.isTablet ? 600.0 : double.infinity);

    if (isTabletOrDesktop || centerOnMobile) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          padding: padding,
          child: child,
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
  }
}

/// Centered grid view for tablet/desktop layouts
class ResponsiveCenteredGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;
  final double? maxWidth;

  const ResponsiveCenteredGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = SizeConfig.gridCount(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    final grid = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );

    // Center on tablet/desktop
    if (SizeConfig.isTablet || SizeConfig.isDesktop) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? SizeConfig.maxContentWidth,
          ),
          child: grid,
        ),
      );
    }

    return grid;
  }
}
