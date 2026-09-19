// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

enum ChatRole { user, model }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.sources = const [],
    this.messageId,
    this.isReported = false,
  });

  final ChatRole role;
  final String text;
  final List<MwalimuAiSource> sources;
  final String? messageId;
  final bool isReported;
}

class IntakeContextCard extends StatelessWidget {
  const IntakeContextCard({required this.topic, this.detail});

  final String topic;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final hasDetail = detail != null && detail!.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                AppDecorations.pastelPanel(context, context.colors.surface),
            child:
                Icon(Icons.assignment_outlined, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muktadha uliotumwa'.tr(context),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasDetail
                      ? '${topic.tr(context)} - ${detail!.tr(context)}'
                      : topic.tr(context),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.onEscalate,
    required this.onReport,
  });

  final ChatMessage message;
  final VoidCallback onEscalate;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final showActions = !isUser &&
        (message.sources.isNotEmpty ||
            message.text.toLowerCase().contains('mtaalamu') ||
            message.text.toLowerCase().contains('whatsapp'));
    final canReport = !isUser && message.messageId != null;
    const bubbleRadius = Radius.circular(AppRadius.xl);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                color: context.colors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color:
                    isUser ? context.colors.primary : context.colors.surface,
                border: isUser
                    ? null
                    : Border.all(color: context.colors.borderSubtle),
                borderRadius: BorderRadius.only(
                  topLeft: bubbleRadius,
                  topRight: bubbleRadius,
                  bottomLeft:
                      Radius.circular(isUser ? AppRadius.xl : AppRadius.sm),
                  bottomRight:
                      Radius.circular(isUser ? AppRadius.sm : AppRadius.xl),
                ),
                boxShadow: AppElevation.soft(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        'Mwalimu AI',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  Text(
                    message.text.tr(context),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? context.colors.onPrimary
                              : context.colors.textPrimary,
                          fontWeight:
                              isUser ? FontWeight.w500 : FontWeight.normal,
                          height: 1.35,
                        ),
                  ),
                  if (!isUser && message.sources.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    ...message.sources.map(
                      (source) => SourceCard(source: source),
                    ),
                  ],
                  if (showActions) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (message.sources.isNotEmpty)
                          ReplyActionChip(
                            icon: Icons.description_outlined,
                            label: 'Ona Kwenye Mafunzo'.tr(context),
                          ),
                        ReplyActionChip(
                          icon: Icons.support_agent,
                          label: 'Msaidizi wa Binadamu'.tr(context),
                          onTap: () {
                            AppFeedback.tap();
                            onEscalate();
                          },
                        ),
                      ],
                    ),
                  ],
                  if (canReport) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: message.isReported ? null : onReport,
                      icon: Icon(
                        message.isReported ? Icons.flag : Icons.flag_outlined,
                        size: 18,
                      ),
                      label: Text(
                        (message.isReported
                            ? 'Jibu limeripotiwa'
                            : 'Ripoti jibu hili').tr(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceCard extends StatelessWidget {
  const SourceCard({required this.source});

  final MwalimuAiSource source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            size: 20,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title.tr(context),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  source.courseTitle.tr(context),
                  style: accessibleCaption(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  source.excerpt.tr(context),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReplyActionChip extends StatelessWidget {
  const ReplyActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceAqua,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InteractiveInk(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: context.colors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
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

class TypingBubble extends StatelessWidget {
  const TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mwalimu AI anaandika'.tr(context),
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.colors.borderSubtle),
          boxShadow: AppElevation.soft(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Mwalimu AI anaandika…'.tr(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
