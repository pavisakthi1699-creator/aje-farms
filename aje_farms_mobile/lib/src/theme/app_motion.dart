import 'package:flutter/widgets.dart';

/// Motion constants aligned with the Chuo Kikuu Cha Mtaani design system.
class AppMotion {
  static const Duration quick = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration enter = Duration(milliseconds: 320);
  static const Duration skeleton = Duration(milliseconds: 1400);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;

  static const double pressScale = 0.985;

  /// True when the platform or user requests reduced motion.
  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Returns [Duration.zero] when reduced motion is requested.
  static Duration durationOf(BuildContext context, Duration duration) {
    return reduceMotionOf(context) ? Duration.zero : duration;
  }
}
