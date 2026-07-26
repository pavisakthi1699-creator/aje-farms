// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

/// Severity of a transient message, driving colour, icon, and haptic.
enum SnackTone { neutral, success, error }

/// Shows a floating snack bar.
///
/// Prefer [showErrorSnack] / [showSuccessSnack] so that failures are not
/// visually indistinguishable from confirmations.
void showSnack(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.colors;

  switch (tone) {
    case SnackTone.neutral:
      AppFeedback.tap();
    case SnackTone.success:
      AppFeedback.success();
    case SnackTone.error:
      AppFeedback.error();
  }

  // The tone is carried by a coloured icon on the themed charcoal fill rather
  // than by tinting the whole surface: white body text over the semantic
  // error/success colours only reaches ~4.1:1, below the 4.5:1 required for
  // normal text. Each tone icon clears the 3:1 threshold against charcoal.
  final (IconData? icon, Color? iconColor) = switch (tone) {
    SnackTone.neutral => (null, null),
    SnackTone.success => (Icons.check_circle_outline, colors.success),
    SnackTone.error => (Icons.error_outline, colors.error),
  };

  final messenger = ScaffoldMessenger.of(context);
  // Replace any queued snack so a burst of failures does not make the user wait
  // out a stale message before seeing the current one.
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      // Errors need longer than the 4s default to be read and acted on.
      duration: tone == SnackTone.error
          ? const Duration(seconds: 6)
          : const Duration(seconds: 4),
      content: Row(
        children: [
          if (icon != null) ...[
            // Distinct icon shapes, not just colour, so the tone survives
            // colour-blindness and greyscale per `color-not-decorative-only`.
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: Text(message)),
        ],
      ),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, onPressed: onAction)
          : null,
    ),
  );
}

/// Reports a failure, optionally offering a recovery path.
void showErrorSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showSnack(
    context,
    message,
    tone: SnackTone.error,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// Confirms a completed action.
void showSuccessSnack(BuildContext context, String message) {
  showSnack(context, message, tone: SnackTone.success);
}
