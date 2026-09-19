import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Centers content and caps width on large phones and tablets.
class AppLayout extends StatelessWidget {
  const AppLayout({
    required this.child,
    this.maxWidth = 720,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: child,
        ),
      ),
    );
  }
}

/// Expands a child toward the viewport width while nested under [AppLayout].
/// Uses [Align] + explicit width (safe for scroll views; no negative padding).
class AppLayoutFullBleed extends StatelessWidget {
  const AppLayoutFullBleed({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final targetWidth =
            viewportWidth.clamp(constraints.maxWidth, viewportWidth);
        if (targetWidth <= constraints.maxWidth) {
          return child;
        }
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: targetWidth,
            child: child,
          ),
        );
      },
    );
  }
}

/// Full-width [header] above width-capped [body] inside one [ListView].
class AppLayoutScroll extends StatelessWidget {
  const AppLayoutScroll({
    required this.header,
    required this.body,
    this.padding = EdgeInsets.zero,
    this.bodyPadding = EdgeInsets.zero,
    super.key,
  });

  final Widget header;
  final Widget body;
  final EdgeInsets padding;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [
        header,
        AppLayout(
          child: Padding(
            padding: bodyPadding,
            child: body,
          ),
        ),
      ],
    );
  }
}
