// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ProblemCategoryTile extends StatelessWidget {
  const ProblemCategoryTile({
    required this.category,
    required this.onTap,
    super.key,
  });

  final ProblemCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InteractiveInk(
        borderRadius: AppRadius.lg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: category.color.withValues(alpha: 0.12),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(category.title,
                  style: Theme.of(context).textTheme.titleSmall ??
                      const TextStyle()),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.muted,
                        height: 1.25,
                      ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final example in category.examples)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        example,
                        style: accessibleCaption(
                          context,
                          color: category.color,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnknownProblemTile extends StatelessWidget {
  const UnknownProblemTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InteractiveInk(
        borderRadius: AppRadius.lg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.colors.surfaceLavender,
                child: Icon(Icons.help_outline, color: context.colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sijui tatizo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Mwalimu AI itakusaidia kuandaa maelezo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Icon(Icons.chevron_right, color: context.colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrendingTopics extends StatelessWidget {
  const TrendingTopics();

  static const _icons = [
    Icons.local_florist,
    Icons.grass,
    Icons.pets,
    Icons.more_horiz,
  ];

  void _openTopic(BuildContext context, String topic) {
    AppFeedback.tap();
    AppNavigator.pushAiChat(
      context,
      initialPromptTopic: topic,
      initialPrompt: 'Nahitaji ushauri kuhusu $topic.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.dependencies.learningRepository.homeTopics;
    final accessibilityScale =
        (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0);
    final cardWidth = 132 + (88 * accessibilityScale);
    final cardHeight = 120 + (80 * accessibilityScale);
    final itemColors = [
      context.colors.primary,
      context.colors.error,
      context.colors.success,
      context.colors.secondary,
    ];
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, index) {
          final topic = topics[index];
          return AccessibleTappable(
            label: topic,
            hint: 'Uliza Mwalimu AI kuhusu ${topic.toLowerCase()}',
            onTap: () => _openTopic(context, topic),
            child: InteractiveInk(
              borderRadius: AppRadius.lg,
              onTap: () => _openTopic(context, topic),
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: AppElevation.borderSubtle(context),
                  boxShadow: AppElevation.soft(context),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icons[index], color: itemColors[index]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      topic,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
