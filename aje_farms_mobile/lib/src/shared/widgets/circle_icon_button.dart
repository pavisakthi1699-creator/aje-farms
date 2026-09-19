import 'package:flutter/material.dart';

import '../../theme/app_a11y.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_feedback.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.size = AppA11y.minTouchTarget,
    super.key,
  }) : assert(
          tooltip != null || semanticLabel != null,
          'CircleIconButton requires tooltip or semanticLabel for accessibility',
        );

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? tooltip!;
    final enabled = onPressed != null;
    final iconColor = enabled
        ? context.colors.primary
        : context.colors.muted.withValues(alpha: 0.6);

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: MinTouchTarget(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: context.colors.primary.withValues(alpha: 0.1),
            highlightColor: context.colors.primary.withValues(alpha: 0.05),
            onTap: !enabled
                ? null
                : () {
                    AppFeedback.tap();
                    onPressed!();
                  },
            child: Container(
              width: size,
              height: size,
              decoration: AppDecorations.circleIconButton(context),
              child: Icon(icon, size: 22, color: iconColor),
            ),
          ),
        ),
      ),
    );

    return Tooltip(message: tooltip ?? label, child: button);
  }
}

class CircleIconButtonSmall extends CircleIconButton {
  const CircleIconButtonSmall({
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.semanticLabel,
    super.key,
  }) : super(size: 40);
}
