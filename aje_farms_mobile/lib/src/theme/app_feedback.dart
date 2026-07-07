import 'package:flutter/services.dart';

/// Lightweight haptic feedback for key interactions.
class AppFeedback {
  static void tap() => HapticFeedback.lightImpact();

  static void selection() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();
}
