import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class SizeConfig {
  static late double width;
  static late double height;
  static late DeviceType deviceType;
  static late double textScale;
  static late EdgeInsets padding;

  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    width = mediaQuery.size.width;
    height = mediaQuery.size.height;
    padding = mediaQuery.padding;
    textScale = mediaQuery.textScaler.scale(1).clamp(0.8, 1.2);

    // Determine device type
    if (width < mobileMaxWidth) {
      deviceType = DeviceType.mobile;
    } else if (width < tabletMaxWidth) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool get isMobile => deviceType == DeviceType.mobile;

  /// Check if device is tablet
  static bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if device is desktop
  static bool get isDesktop => deviceType == DeviceType.desktop;

  /// Get responsive value based on device type
  static T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Get adaptive width (percentage of screen width)
  static double w(double percentage) => width * (percentage / 100);

  /// Get adaptive height (percentage of screen height)
  static double h(double percentage) => height * (percentage / 100);

  /// Get adaptive font size that scales well
  static double fontSize(double size) {
    final double scaleFactor = responsive(
      mobile: 1.0,
      tablet: 1.15,
      desktop: 1.25,
    );
    return size * scaleFactor * textScale;
  }

  /// Get adaptive spacing
  static double spacing(double value) {
    return responsive(
      mobile: value,
      tablet: value * 1.25,
      desktop: value * 1.5,
    );
  }

  /// Get adaptive border radius
  static double radius(double value) {
    return responsive(
      mobile: value,
      tablet: value * 1.1,
      desktop: value * 1.2,
    );
  }

  /// Get adaptive icon size
  static double iconSize(double value) {
    return responsive(
      mobile: value,
      tablet: value * 1.2,
      desktop: value * 1.4,
    );
  }

  /// Get grid cross axis count based on device
  static int gridCount({
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    return responsive(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Maximum content width for centering on large screens
  static double get maxContentWidth {
    return responsive(
      mobile: width,
      tablet: 700,
      desktop: 1200,
    );
  }

  /// Horizontal padding that adjusts to screen size
  static double get horizontalPadding {
    return responsive(
      mobile: width * 0.04,
      tablet: width * 0.06,
      desktop: width * 0.08,
    );
  }

  /// Vertical padding that adjusts to screen size
  static double get verticalPadding {
    return responsive(
      mobile: height * 0.02,
      tablet: height * 0.025,
      desktop: height * 0.03,
    );
  }
}
