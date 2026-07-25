// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";
import "package:url_launcher/url_launcher.dart";

class LearningSummaryCard extends StatelessWidget {
  const LearningSummaryCard({required this.courses});

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final completedLessons = courses
        .expand((course) => course.lessons.map((lesson) {
              return lesson.isCompleted ||
                  session.isLessonCompleted(lessonProgressKey(course, lesson));
            }))
        .where((isCompleted) => isCompleted)
        .length;
    final totalLessons =
        courses.expand((course) => course.lessons).toList().length;

    return Card(
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: AppA11y.minTouchTarget,
              height: AppA11y.minTouchTarget,
              decoration: AppDecorations.circleIconButton(context),
              child:
                  Icon(Icons.menu_book_outlined, color: context.colors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maktaba yako',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$completedLessons kati ya $totalLessons yamekamilika kwenye mafunzo yako.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final completed = course.lessons.where((lesson) {
      return lesson.isCompleted ||
          session.isLessonCompleted(lessonProgressKey(course, lesson));
    }).length;
    final total = course.lessons.length;
    final hasPremium = course.lessons.any((lesson) => lesson.isPremium);
    final progress = total == 0 ? 0.0 : completed / total;

    return Semantics(
      button: true,
      label: 'Fungua kozi ya ${course.title}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppFeedback.tap();
            AppNavigator.pushCourse(context, course);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkPhoto(url: course.imageUrl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              context.colors.charcoal.withValues(alpha: 0.28),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        top: AppSpacing.lg,
                        child: Pill(label: course.badge),
                      ),
                      Positioned(
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color:
                                context.colors.charcoal.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '$completed/$total masomo',
                            style: accessibleCaption(
                              context,
                              color: context.colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      course.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.muted,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      label:
                          '${(progress * 100).round()}% ya ${course.title} imekamilika',
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
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          progress > 0
                              ? '${(progress * 100).round()}% imekamilika'
                              : 'Tayari kuanza',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const Spacer(),
                        if (hasPremium)
                          Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 16, color: context.colors.muted),
                              const SizedBox(width: AppSpacing.xs),
                              Text('Premium',
                                  style: accessibleCaption(context)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () {
                        AppFeedback.tap();
                        AppNavigator.pushCourse(context, course);
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Anza Kujifunza'),
                      style: FilledButton.styleFrom(
                          backgroundColor: context.colors.charcoal),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppFeedback.tap();
                              AppNavigator.pushAiChat(
                                context,
                                initialPromptTopic: course.title,
                              );
                            },
                            icon: const Icon(Icons.smart_toy_outlined),
                            label: const Text('Uliza AI'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppFeedback.tap();
                              AppNavigator.pushWhatsApp(context);
                            },
                            icon: const Icon(Icons.support_agent),
                            label: const Text('Mtaalamu'),
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
    );
  }
}

class CourseProgressSummary extends StatelessWidget {
  const CourseProgressSummary({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final completed = course.lessons.where((lesson) {
      return lesson.isCompleted ||
          context.session.isLessonCompleted(lessonProgressKey(course, lesson));
    }).length;
    final total = course.lessons.length;

    return Card(
      color: context.colors.mint,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.insights, color: context.colors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mwendelezo wa kozi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: completed / total,
                minHeight: 8,
                backgroundColor: context.colors.surface,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              courseProgressMessage(completed: completed, total: total),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String courseProgressMessage({
  required int completed,
  required int total,
}) {
  if (completed == 0) {
    return 'Anza na somo la kwanza kisha fuata mpangilio wa masomo.';
  }
  if (completed < total) {
    return 'Umekamilisha somo $completed kati ya $total. Endelea na somo linalofuata.';
  }
  return 'Umemaliza masomo yote. Unaweza kurudia masomo au kumuuliza Mwalimu AI swali la kozi.';
}

class LessonTile extends StatelessWidget {
  const LessonTile({
    required this.lesson,
    required this.isCompleted,
    required this.onTap,
  });

  final Lesson lesson;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isCompleted ? context.colors.primary : context.colors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
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
                  radius: 28,
                  backgroundColor: lesson.isPremium
                      ? context.colors.surfaceMuted
                      : context.colors.surfaceAqua,
                  child: Icon(
                    lesson.isPremium
                        ? Icons.lock_outline
                        : isCompleted
                            ? Icons.check_circle
                            : lesson.type.icon,
                    color: lesson.isPremium
                        ? context.colors.muted
                        : context.colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${lesson.type.label} - ${lesson.meta}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lesson.isPremium
                            ? 'Fungua premium kuendelea'
                            : isCompleted
                                ? 'Umekamilisha'
                                : 'Bado hujaanza',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  lesson.isPremium ? Icons.lock_outline : Icons.chevron_right,
                  color: context.colors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LessonPreviewSheet extends StatelessWidget {
  const LessonPreviewSheet({
    required this.courseId,
    required this.lessonId,
    required this.lessonProgressKey,
    required this.lesson,
    required this.courseTitle,
  });

  final String courseId;
  final String lessonId;
  final String lessonProgressKey;
  final Lesson lesson;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.borderSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.colors.primaryContainer,
                  child: Icon(lesson.type.icon, color: context.colors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '$courseTitle - ${lesson.type.label}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              lesson.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (lesson.sourceTitle != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 18,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Chanzo: ${lesson.sourceTitle}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (lesson.type == LessonType.video) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: lesson.resourceUrl == null
                    ? null
                    : () => _openVideo(context, lesson),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(
                  lesson.resourceUrl == null
                      ? 'Video bado haijachapishwa'
                      : 'Tazama Video',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                AppFeedback.tap();
                final session = context.session;
                final learningProgressService =
                    context.dependencies.learningProgressService;
                await session.markLessonCompleted(lessonProgressKey);
                final phoneNumber = session.phoneNumber;
                if (phoneNumber != null && session.isSignedIn) {
                  try {
                    await learningProgressService.markLessonCompleted(
                      phoneNumber: phoneNumber,
                      courseId: courseId,
                      lessonId: lessonId,
                    );
                  } on LearningProgressException catch (error) {
                    if (context.mounted) {
                      showSnack(context, error.message);
                    }
                  }
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showSnack(context, '${lesson.type.label}: ${lesson.title}');
              },
              icon: Icon(lesson.type.icon),
              label: const Text('Kamilisha Somo'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openVideo(BuildContext context, Lesson lesson) async {
  final resourceUrl = lesson.resourceUrl;
  if (resourceUrl == null) return;
  final lessonId = lesson.id;
  final catalogService = context.dependencies.catalogService;

  // Backend-hosted videos are behind a session, so resolve them to a signed URL
  // first. Externally hosted videos are already playable as-is.
  var playableUrl = resourceUrl;
  if (lessonId != null && resourceUrl.contains('/api/lessons/')) {
    try {
      playableUrl = await catalogService.lessonVideoUrl(lessonId);
    } on CatalogException catch (error) {
      if (context.mounted) showSnack(context, error.message);
      return;
    }
  }

  final uri = Uri.tryParse(playableUrl);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      showSnack(context, 'Video haikuweza kufunguka. Jaribu tena baadaye.');
    }
  }
}

String lessonProgressKey(Course course, Lesson lesson) {
  return '${course.id}:${lessonContentId(lesson)}';
}

String lessonContentId(Lesson lesson) {
  return lesson.id ?? _slug(lesson.title);
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}

class AskAiPanel extends StatelessWidget {
  const AskAiPanel({required this.courseTitle, required this.onTap});

  final String courseTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.mint,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Una swali gani?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mwalimu AI yuko tayari kujibu maswali kuhusu $courseTitle',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                AppFeedback.tap();
                onTap();
              },
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Uliza AI Sasa'),
            ),
          ],
        ),
      ),
    );
  }
}
