import 'package:flutter/material.dart';

/// Window-width breakpoints for adaptive layouts (not hardware types).
abstract final class AppBreakpoints {
  /// Single-column nav and stacked lists (typical phones).
  static const expandedMinWidth = 600.0;

  /// Side [NavigationRail] instead of bottom bar (tablets / wide windows).
  /// Kept above the default 800×600 test surface so widget tests stay stable.
  static const railMinWidth = 840.0;

  static bool isExpanded(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= expandedMinWidth;
  }

  static bool useNavigationRail(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= railMinWidth;
  }
}
