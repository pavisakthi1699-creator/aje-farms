import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import 'loading_skeleton.dart';

class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return AnimatedOpacity(
            opacity: frame == null && !wasSynchronouslyLoaded ? 0 : 1,
            duration: AppMotion.durationOf(context, AppMotion.standard),
            curve: AppMotion.emphasized,
            child: child,
          );
        }
        return ColoredBox(
          color: context.colors.primaryContainer,
          child: Center(
            child: LoadingSkeleton(
              width: 72,
              height: 72,
              borderRadius: AppRadius.xl,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: context.colors.primaryContainer,
        child: Icon(
          Icons.landscape_outlined,
          color: context.colors.primary,
          size: 44,
        ),
      ),
    );
  }
}
