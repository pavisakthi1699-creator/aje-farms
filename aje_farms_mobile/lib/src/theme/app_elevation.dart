import 'package:flutter/material.dart';

import 'app_color_scheme.dart';

class AppElevation {
  AppElevation._();

  static Color shadowColor(AppColorScheme colors) =>
      colors.textPrimary.withValues(alpha: 0.10);

  static List<BoxShadow> soft(BuildContext context) {
    final color = shadowColor(context.colors);
    return [
      BoxShadow(
        color: color,
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: -6,
      ),
    ];
  }

  static List<BoxShadow> float(BuildContext context) {
    final color = context.colors.textPrimary.withValues(alpha: 0.14);
    return [
      BoxShadow(
        color: color,
        blurRadius: 32,
        offset: const Offset(0, 14),
        spreadRadius: -8,
      ),
    ];
  }

  static Border borderSubtle(BuildContext context) =>
      Border.all(color: context.colors.borderSubtle);
}
