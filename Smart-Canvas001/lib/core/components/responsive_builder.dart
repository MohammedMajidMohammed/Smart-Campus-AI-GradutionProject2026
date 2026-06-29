import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

/// A widget that provides responsive layout capabilities
/// based on the current device type (mobile, tablet, desktop)
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, SizeConfig config)? mobile;
  final Widget Function(BuildContext context, SizeConfig config)? tablet;
  final Widget Function(BuildContext context, SizeConfig config)? desktop;
  final Widget Function(BuildContext context, SizeConfig config)? builder;

  const ResponsiveBuilder({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.builder,
  }) : assert(
          builder != null || mobile != null,
          'Either builder or mobile must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Re-initialize SizeConfig with current context
        SizeConfig.init(context);

        // Use builder for all if provided
        if (builder != null) {
          return builder!(context, SizeConfig());
        }

        // Otherwise use device-specific builders
        switch (SizeConfig.deviceType) {
          case DeviceType.desktop:
            return (desktop ?? tablet ?? mobile)!(context, SizeConfig());
          case DeviceType.tablet:
            return (tablet ?? mobile)!(context, SizeConfig());
          case DeviceType.mobile:
            return mobile!(context, SizeConfig());
        }
      },
    );
  }
}

/// A container that centers content with max width on large screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      alignment: Alignment.center,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: SizeConfig.horizontalPadding,
            vertical: SizeConfig.verticalPadding,
          ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? SizeConfig.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

/// A row that becomes a column on mobile devices
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool? forceColumn;
  final bool? forceRow;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
    this.forceColumn,
    this.forceRow,
  });

  @override
  Widget build(BuildContext context) {
    final bool useColumn = forceColumn == true ||
        (forceRow != true && SizeConfig.isMobile);

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(
          useColumn
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }

    if (useColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: spacedChildren,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }
}

/// A grid that adjusts columns based on device type
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = SizeConfig.gridCount(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.builder(
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
  }
}
