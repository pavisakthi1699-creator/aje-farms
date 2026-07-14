import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import 'loading_skeleton.dart';

/// Renders bundled assets or remote URLs for course and hero imagery.
class AppPhoto extends StatelessWidget {
  const AppPhoto({required this.source, super.key});

  final String source;

  bool get _isAsset => source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (_isAsset) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return Image.network(
      source,
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
          child: const Center(
            child: LoadingSkeleton(
              width: 72,
              height: 72,
              borderRadius: AppRadius.xl,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: context.colors.primaryContainer,
      child: Icon(
        Icons.landscape_outlined,
        color: context.colors.primary,
        size: 44,
      ),
    );
  }
}
