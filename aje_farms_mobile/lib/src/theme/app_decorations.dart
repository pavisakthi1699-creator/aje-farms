import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_elevation.dart';
import 'app_radius.dart';

class AppDecorations {
  static BoxDecoration surfaceCard(
    BuildContext context, {
    Color? color,
    double radius = AppRadius.xl,
    bool elevated = true,
  }) {
    final colors = context.colors;
    return BoxDecoration(
      color: color ?? colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.borderSubtle),
      boxShadow: elevated ? AppElevation.soft(context) : null,
    );
  }

  static BoxDecoration pastelPanel(
    BuildContext context,
    Color color, {
    double radius = AppRadius.xl,
  }) {
    final colors = context.colors;
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.7)),
    );
  }

  static BoxDecoration charcoalPanel(
    BuildContext context, {
    double radius = AppRadius.xl,
  }) {
    final colors = context.colors;
    return BoxDecoration(
      color: colors.charcoal,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppElevation.float(context),
    );
  }

  static BoxDecoration circleIconButton(BuildContext context) {
    final colors = context.colors;
    return BoxDecoration(
      color: colors.surface,
      shape: BoxShape.circle,
      border: Border.all(color: colors.borderSubtle),
      boxShadow: AppElevation.soft(context),
    );
  }
}
