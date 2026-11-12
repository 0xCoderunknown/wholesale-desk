import 'package:material_ui/material_ui.dart';

/// Single source of truth for responsive breakpoints across Wholesale Desk.
/// Eliminates hardcoded magic width numbers in UI components.
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 767.0;
  static const double tabletMax = 1023.0;
  static const double desktopMin = 1024.0;

  /// Returns true if the screen is a mobile viewport (< 768px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMax;

  /// Returns true if the screen is a tablet viewport (768px – 1023px)
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > mobileMax && w <= tabletMax;
  }

  /// Returns true if the screen is a desktop viewport (>= 1024px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMin;

  /// Pure width checks (for testing or layout builder constraints)
  static bool isMobileWidth(double width) => width <= mobileMax;
  static bool isTabletWidth(double width) => width > mobileMax && width <= tabletMax;
  static bool isDesktopWidth(double width) => width >= desktopMin;
}

