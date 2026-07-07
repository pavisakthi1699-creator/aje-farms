// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class Pill extends StatelessWidget {
  const Pill({required this.label, this.color});

  final String label;
  final Color? color;

  bool _onLightSurface(AppColorScheme colors, Color background) {
    return background == colors.surface ||
        background == colors.surfaceMuted ||
        background == colors.surfaceAqua ||
        background == colors.surfaceLavender ||
        background == colors.surfacePeach;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = color ?? colors.surface;
    final onLight = _onLightSurface(colors, background);
    final textColor = onLight ? colors.textPrimary : colors.onPrimary;

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background.withValues(alpha: onLight ? 0.92 : 1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: onLight
              ? Border.all(color: colors.borderSubtle.withValues(alpha: 0.8))
              : null,
          boxShadow: onLight ? AppElevation.soft(context) : null,
        ),
        child: Text(
          label,
          style: accessibleCaption(
            context,
            color: textColor,
            fontWeight: FontWeight.w600,
          ).copyWith(letterSpacing: 0.2),
        ),
      ),
    );
  }
}
