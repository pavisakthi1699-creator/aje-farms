// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class TrialStatusCard extends StatelessWidget {
  const TrialStatusCard();

  @override
  Widget build(BuildContext context) {
    final session = context.session.state;
    final status = AccountAccessStatus.of(session);
    final title = status.title(session);
    final body = status.body;
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: AppA11y.minTouchTarget,
                height: AppA11y.minTouchTarget,
                decoration: AppDecorations.pastelPanel(
                  context,
                  context.colors.primaryContainer,
                ),
                child: Icon(
                  status.icon,
                  color: context.colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroActionCard extends StatelessWidget {
  const HeroActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AccessibleTappable(
      label: tr('Eleza tatizo la shamba'),
      hint: tr(
        'Chagua aina ya changamoto, ongeza zao au mnyama, kisha Mwalimu AI aanze na muktadha sahihi.',
      ),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          child: InteractiveInk(
            borderRadius: AppRadius.hero,
            onTap: onTap,
            child: Ink(
              decoration: const BoxDecoration(),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  const Positioned.fill(
                    child: AppPhoto(
                      source: 'assets/images/hero/farm-field.jpg',
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withValues(alpha: 0.88),
                            colors.primaryDark.withValues(alpha: 0.94),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Stack(
                      children: [
                        const Positioned(
                          right: -4,
                          top: -4,
                          child: Opacity(
                            opacity: 0.18,
                            child: BrandMark(
                              size: 112,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Pill(
                              label: tr('Kipaumbele cha leo'),
                              color: colors.accentWarm,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(
                              tr('Eleza tatizo la shamba'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: colors.onPrimary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              tr(
                                'Chagua aina ya changamoto, ongeza zao au mnyama, kisha Mwalimu AI aanze na muktadha sahihi.',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: colors.onPrimarySubtle),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            ExcludeSemantics(
                              child: FilledButton.icon(
                                onPressed: () {
                                  AppFeedback.tap();
                                  onTap();
                                },
                                icon: const Icon(Icons.search),
                                label: Text(tr('Eleza tatizo')),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(
                                    170,
                                    AppA11y.minTouchTarget,
                                  ),
                                  backgroundColor: colors.surface,
                                  foregroundColor: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiniActionCard extends StatelessWidget {
  const MiniActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.foreground,
  });

  final Color color;
  final Color? foreground;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = this.foreground ?? colors.textPrimary;
    final isDark = foreground == colors.onPrimary;
    return AccessibleTappable(
      label: title,
      hint: subtitle,
      onTap: onTap,
      child: Card(
        color: color,
        child: InteractiveInk(
          key: ValueKey('mini-action-$title'),
          borderRadius: AppRadius.xl,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.colors.onPrimaryFaint
                          : context.colors.surface,
                      shape: BoxShape.circle,
                      border: isDark
                          ? null
                          : Border.all(color: context.colors.borderSubtle),
                      boxShadow: isDark ? null : AppElevation.soft(context),
                    ),
                    child: Icon(
                      icon,
                      color: isDark
                          ? context.colors.onPrimary
                          : context.colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: accessibleCaption(
                      context,
                      color: foreground.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({
    required this.course,
    required this.onTap,
    super.key,
  });

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = course.lessons.where((lesson) {
      return lesson.isCompleted ||
          context.session.isLessonCompleted(lessonProgressKey(course, lesson));
    }).length;
    final total = course.lessons.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final nextLesson = course.lessons.cast<Lesson?>().firstWhere(
          (lesson) =>
              lesson != null &&
              !lesson.isCompleted &&
              !context.session
                  .isLessonCompleted(lessonProgressKey(course, lesson)),
          orElse: () => null,
        );
    final progressLabel = tr('{percent}% ya {title} imekamilika', {
      'percent': (progress * 100).round(),
      'title': course.title,
    });
    return AccessibleTappable(
      label: tr('Endelea na kozi {title}', {'title': course.title}),
      hint: progressLabel,
      onTap: onTap,
      child: Card(
        child: InteractiveInk(
          key: ValueKey('dashboard-course-tap-${course.id}'),
          borderRadius: AppRadius.xl,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 94,
                    height: 94,
                    child: NetworkPhoto(url: course.imageUrl),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        nextLesson == null
                            ? tr('Masomo yote yamekamilika')
                            : tr('Somo linalofuata: {title}', {
                                'title': nextLesson.title,
                              }),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            tr('{completed}/{total} masomo', {
                              'completed': completed,
                              'total': total,
                            }),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Semantics(
                        label: progressLabel,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: context.colors.surfaceMuted,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        tr('Endelea na kozi'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
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
