

library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

enum ScreenOrientation {
  portrait,
  landscape,
}

class ResponsiveUtils {
  ResponsiveUtils._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static ScreenOrientation getOrientation(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;
  }

  static bool isLandscape(BuildContext context) =>
      getOrientation(context) == ScreenOrientation.landscape;

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

  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 16.0,
      tablet: 32.0,
      desktop: 64.0,
    );
  }

  static double responsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return responsiveValue(
      context,
      mobile: screenWidth - 32,
      tablet: (screenWidth - 72) / 2,
      desktop: (screenWidth - 160) / 3,
    );
  }

  static int responsiveGridColumns(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

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

  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.paddingOf(context);
  }

  static Size getScreenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom > 0;
  }

  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom;
  }

  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    return responsiveValue(
      context,
      mobile: screenWidth,
      tablet: screenWidth * 0.85,
      desktop: 1200.0,
    );
  }
}

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

    return builder(context, deviceType);
  }
}

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

extension ResponsiveExtension on BuildContext {

  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);

  bool get isMobile => ResponsiveUtils.isMobile(this);

  bool get isTablet => ResponsiveUtils.isTablet(this);

  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  double get screenWidth => ResponsiveUtils.getScreenWidth(this);

  double get screenHeight => ResponsiveUtils.getScreenHeight(this);

  EdgeInsets get safeAreaPadding => ResponsiveUtils.getSafeAreaPadding(this);

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
