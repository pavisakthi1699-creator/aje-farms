import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Soft fade-and-rise when async content replaces a loading state.
class FadeInContent extends StatelessWidget {
  const FadeInContent({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotionOf(context)) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(child.runtimeType),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.enter,
      curve: AppMotion.emphasized,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
