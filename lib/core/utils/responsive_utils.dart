/// Enterprise-level Responsive Utilities
/// Ensures consistent UI across all device sizes (mobile, tablet, desktop, web)
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Screen orientation
enum ScreenOrientation {
  portrait,
  landscape,
}

/// Responsive utility class for cross-device compatibility
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoints (following Material Design guidelines)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Get current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if running on mobile device
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if running on tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if running on desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Get current screen orientation
  static ScreenOrientation getOrientation(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;
  }

  /// Check if in landscape mode
  static bool isLandscape(BuildContext context) =>
      getOrientation(context) == ScreenOrientation.landscape;

  /// Get responsive value based on device type
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static double responsiveHorizontalPadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 16.0,
      tablet: 32.0,
      desktop: 64.0,
    );
  }

  /// Get responsive card width (for grid layouts)
  static double responsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return responsiveValue(
      context,
      mobile: screenWidth - 32,
      tablet: (screenWidth - 72) / 2,
      desktop: (screenWidth - 160) / 3,
    );
  }

  /// Get number of grid columns
  static int responsiveGridColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get grid cross axis count with customizable columns per device
  static int getGridCrossAxisCount(
    BuildContext context, {
    int baseColumns = 2,
    int? tabletColumns,
    int? desktopColumns,
  }) {
    return responsiveValue(
      context,
      mobile: baseColumns,
      tablet: tabletColumns ?? baseColumns + 1,
      desktop: desktopColumns ?? baseColumns + 2,
    );
  }

  /// Get responsive font size
  static double responsiveFontSize(
    BuildContext context, {
    required double base,
    double? tabletMultiplier,
    double? desktopMultiplier,
  }) {
    return responsiveValue(
      context,
      mobile: base,
      tablet: base * (tabletMultiplier ?? 1.1),
      desktop: base * (desktopMultiplier ?? 1.2),
    );
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.paddingOf(context);
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom;
  }

  /// Get max content width (for centered layouts on wide screens)
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    return responsiveValue(
      context,
      mobile: screenWidth,
      tablet: screenWidth * 0.85,
      desktop: 1200.0, // Max width for desktop
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Named constructor for providing separate widgets
  const ResponsiveBuilder.widgets({
    super.key,
    required Widget this.mobile,
    this.tablet,
    this.desktop,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, DeviceType deviceType) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);

    // If using named constructor with widgets
    if (mobile != null) {
      switch (deviceType) {
        case DeviceType.desktop:
          return desktop ?? tablet ?? mobile!;
        case DeviceType.tablet:
          return tablet ?? mobile!;
        case DeviceType.mobile:
          return mobile!;
      }
    }

    // Using builder function
    return builder(context, deviceType);
  }
}

/// Responsive container that centers content on wide screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? ResponsiveUtils.getMaxContentWidth(context);
    final effectivePadding =
        padding ?? ResponsiveUtils.responsivePadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid that adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.responsiveValue(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children.map((child) {
              return SizedBox(
                width: itemWidth,
                child: child,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Extension for responsive sizing
extension ResponsiveExtension on BuildContext {
  /// Get device type
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);

  /// Check if mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Check if landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  /// Screen width
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);

  /// Screen height
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);

  /// Safe area padding
  EdgeInsets get safeAreaPadding => ResponsiveUtils.getSafeAreaPadding(this);

  /// Responsive value helper
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      ResponsiveUtils.responsiveValue(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}
