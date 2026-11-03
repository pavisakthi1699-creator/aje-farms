import 'package:flutter/material.dart';
import '../../state/app_session.dart';
import '../../theme/app_feedback.dart';
import '../../theme/app_spacing.dart';

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionController = AppSessionScope.of(context);
    final isEn = sessionController.state.languagePreference.languageCode == 'en';

    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () {
        AppFeedback.selection();
        sessionController.setLanguagePreference(
          isEn ? const Locale('sw') : const Locale('en'),
        );
      },
      icon: const Icon(Icons.language, size: 18),
      label: Text(
        isEn ? 'EN' : 'SW',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
