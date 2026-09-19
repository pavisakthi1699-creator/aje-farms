import 'package:flutter/services.dart';

/// Lightweight haptic feedback for key interactions.
class AppFeedback {
  static void tap() => HapticFeedback.lightImpact();

  static void selection() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();

  /// Distinct from [success] so a failure is not confirmed by the same buzz as
  /// a completed action.
  static void error() => HapticFeedback.heavyImpact();
}
