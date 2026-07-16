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

  static const _items = [
    (
      Icons.water_drop,
      'Maji',
      'Nahitaji ushauri kuhusu maji kwenye shamba langu.'
    ),
    (
      Icons.bug_report,
      'Wadudu',
      'Nahitaji ushauri kuhusu wadudu kwenye shamba langu.'
    ),
    (
      Icons.eco,
      'Mbolea',
      'Nisaidie kuandaa taarifa za udongo kabla ya kuchagua mbolea.'
    ),
    (Icons.trending_up, 'Soko', 'Nahitaji ushauri kuhusu soko la mazao yangu.'),
  ];

  void _openTopic(BuildContext context, String topic, String prompt) {
    AppFeedback.tap();
    AppNavigator.pushAiChat(
      context,
      initialPromptTopic: topic,
      initialPrompt: prompt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemColors = [
      context.colors.primary,
      context.colors.error,
      context.colors.success,
      context.colors.secondary,
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, index) {
          final item = _items[index];
          return AccessibleTappable(
            label: item.$2,
            hint: 'Uliza Mwalimu AI kuhusu ${item.$2.toLowerCase()}',
            onTap: () => _openTopic(context, item.$2, item.$3),
            child: InteractiveInk(
              borderRadius: AppRadius.lg,
              onTap: () => _openTopic(context, item.$2, item.$3),
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: AppElevation.borderSubtle(context),
                  boxShadow: AppElevation.soft(context),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: itemColors[index]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.$2,
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
