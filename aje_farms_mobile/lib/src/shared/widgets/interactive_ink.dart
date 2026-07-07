import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_feedback.dart';
import '../../theme/app_motion.dart';

/// Ink ripple with a subtle press scale and haptic feedback.
class InteractiveInk extends StatefulWidget {
  const InteractiveInk({
    required this.onTap,
    required this.child,
    this.borderRadius = 0,
    this.enabled = true,
    this.enableHaptic = true,
    super.key,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double borderRadius;
  final bool enabled;
  final bool enableHaptic;

  @override
  State<InteractiveInk> createState() => InteractiveInkState();
}

class InteractiveInkState extends State<InteractiveInk> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final reduceMotion = AppMotion.reduceMotionOf(context);

    final ink = InkWell(
      borderRadius: radius,
      splashColor: context.colors.primary.withValues(alpha: 0.08),
      highlightColor: context.colors.primary.withValues(alpha: 0.04),
      onHighlightChanged:
          widget.enabled && !reduceMotion ? _setPressed : null,
      onTap: !widget.enabled || widget.onTap == null
          ? null
          : () {
              if (widget.enableHaptic) {
                AppFeedback.tap();
              }
              widget.onTap!();
            },
      child: widget.child,
    );

    if (reduceMotion) {
      return ink;
    }

    return AnimatedScale(
      scale: _pressed ? AppMotion.pressScale : 1,
      duration: AppMotion.quick,
      curve: AppMotion.standardCurve,
      child: ink,
    );
  }
}
