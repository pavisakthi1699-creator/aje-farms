import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_feedback.dart';
import '../../theme/app_spacing.dart';

/// Asks the user to confirm an action before it runs.
///
/// Returns `true` only on explicit confirmation; dismissing via the scrim, the
/// cancel button, or the system back gesture all resolve to `false`.
///
/// Set [isDestructive] for actions that discard or hide data — the confirm
/// button then takes the semantic error colour and is visually separated from
/// the safe default, per `destructive-emphasis`.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Ghairi',
  bool isDestructive = false,
}) async {
  final colors = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          // Cancel is listed first and rendered as low-emphasis so the
          // reversible choice is the easy one to hit.
          TextButton(
            onPressed: () {
              AppFeedback.tap();
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(cancelLabel),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onPrimary,
                  )
                : null,
            onPressed: () {
              AppFeedback.tap();
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
