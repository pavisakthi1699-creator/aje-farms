import 'package:flutter/material.dart';

import '../../theme/app_a11y.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_feedback.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Floating message composer used in chat and community reply flows.
class ChatComposerBar extends StatelessWidget {
  const ChatComposerBar({
    required this.controller,
    required this.onSend,
    this.hintText = 'Andika ujumbe…',
    this.isLoading = false,
    this.sendButtonKey,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final bool isLoading;
  final Key? sendButtonKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: DecoratedBox(
          decoration:
              AppDecorations.surfaceCard(context, radius: AppRadius.hero),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isLoading,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: hintText,
                      filled: true,
                      fillColor: context.colors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!isLoading) onSend();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: AppA11y.minTouchTarget,
                  height: AppA11y.minTouchTarget,
                  child: Semantics(
                    button: true,
                    enabled: !isLoading,
                    label: 'Tuma',
                    child: Tooltip(
                      message: 'Tuma',
                      child: FilledButton(
                        key: sendButtonKey,
                        onPressed: isLoading
                            ? null
                            : () {
                                AppFeedback.tap();
                                onSend();
                              },
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
