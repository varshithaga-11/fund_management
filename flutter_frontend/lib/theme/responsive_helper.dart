import 'package:flutter/material.dart';
import 'app_theme.dart';

class ResponsiveHelper {
  // Get the current breakpoint based on screen width
  static Breakpoint getBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.tablet) {
      return Breakpoint.mobile;
    } else if (width < AppBreakpoints.desktop) {
      return Breakpoint.tablet;
    } else if (width < AppBreakpoints.wide) {
      return Breakpoint.desktop;
    } else if (width < AppBreakpoints.ultraWide) {
      return Breakpoint.wide;
    }
    return Breakpoint.ultraWide;
  }
  
  // Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.tablet;
  }
  
  // Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
  }
  
  // Check if current device is desktop and above
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
  }
  
  // Get responsive value based on breakpoint
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
    T? wide,
    T? ultraWide,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet;
      case Breakpoint.desktop:
        return desktop;
      case Breakpoint.wide:
        return wide ?? desktop;
      case Breakpoint.ultraWide:
        return ultraWide ?? wide ?? desktop;
    }
  }
  
  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return ResponsiveHelper.getResponsiveValue(
      context,
      mobile: const EdgeInsets.all(AppSpacing.md),
      tablet: const EdgeInsets.all(AppSpacing.lg),
      desktop: const EdgeInsets.all(AppSpacing.xl),
    );
  }
  
  // Get responsive gap
  static double getResponsiveGap(BuildContext context) {
    return ResponsiveHelper.getResponsiveValue(
      context,
      mobile: AppSpacing.md,
      tablet: AppSpacing.lg,
      desktop: AppSpacing.xl,
    );
  }
}

enum Breakpoint {
  mobile,
  tablet,
  desktop,
  wide,
  ultraWide,
}

class ResponsiveBoxConstraints {
  static const double maxContentWidth = 1400;
  static const double sidebarWidthExpanded = 290;
  static const double sidebarWidthCollapsed = 90;
}
