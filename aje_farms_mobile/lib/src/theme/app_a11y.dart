import 'package:flutter/material.dart';

import 'app_color_scheme.dart';

/// Accessibility constants aligned with the AJE Farms design system.
class AppA11y {
  static const double minTouchTarget = 48;
  static const double minReadableLabel = 12;
  static const double compactBreakpoint = 360;
}

/// Ensures a widget meets the minimum 48×48dp touch target.
class MinTouchTarget extends StatelessWidget {
  const MinTouchTarget({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppA11y.minTouchTarget,
        minHeight: AppA11y.minTouchTarget,
      ),
      child: Center(child: child),
    );
  }
}

/// Wraps a tappable surface with button semantics for screen readers.
class AccessibleTappable extends StatelessWidget {
  const AccessibleTappable({
    required this.label,
    required this.onTap,
    required this.child,
    this.hint,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: child,
    );
  }
}

/// Scales-aware caption text that stays readable at large accessibility sizes.
TextStyle accessibleCaption(
  BuildContext context, {
  Color? color,
  FontWeight fontWeight = FontWeight.w700,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  final size = (AppA11y.minReadableLabel * scale)
      .clamp(
        AppA11y.minReadableLabel,
        18.0,
      )
      .toDouble();
  return Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color ?? context.colors.textSecondary,
            fontSize: size,
            fontWeight: fontWeight,
          ) ??
      TextStyle(
        color: color ?? context.colors.textSecondary,
        fontSize: size,
        fontWeight: fontWeight,
      );
}
