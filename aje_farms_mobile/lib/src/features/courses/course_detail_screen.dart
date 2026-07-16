// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final heroLesson = _heroLesson(context, course);

    return Scaffold(
      body: CustomScrollView(
        key: AppPageStorage.courseDetail(course.id),
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            foregroundColor: context.colors.onPrimary,
            backgroundColor: context.colors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                bottom: AppSpacing.lg,
                end: AppSpacing.xxxl,
              ),
              title: Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(url: course.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.colors.charcoal.withValues(alpha: 0.08),
                          context.colors.charcoal.withValues(alpha: 0.52),
                        ],
                      ),
                    ),
                  ),
                  if (heroLesson != null)
                    Center(
                      child: Semantics(
                        button: true,
                        enabled: true,
                        label: 'Fungua somo la kwanza',
                        child: MinTouchTarget(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: context.colors.onPrimary
                                  .withValues(alpha: 0.12),
                              highlightColor: context.colors.onPrimary
                                  .withValues(alpha: 0.06),
                              onTap: () {
                                AppFeedback.tap();
                                _openLessonPreview(context, course, heroLesson);
                              },
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: context.colors.onPrimaryFaint,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.colors.onPrimaryBorder,
                                  ),
                                  boxShadow: AppElevation.float(context),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: context.colors.onPrimary,
                                  size: 46,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppLayout(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CourseProgressSummary(course: course),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.badge,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: context.colors.secondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              course.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              course.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Malengo ya Somo:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...course.outcomes.map(
                              (outcome) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: context.colors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        outcome,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Masomo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...course.lessons.map(
                      (lesson) => LessonTile(
                        lesson: lesson,
                        isCompleted: lesson.isCompleted ||
                            context.session.isLessonCompleted(
                              lessonProgressKey(course, lesson),
                            ),
                        onTap: () =>
                            _openLessonPreview(context, course, lesson),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AskAiPanel(
                      courseTitle: course.title,
                      onTap: () {
                        AppNavigator.pushAiChat(
                          context,
                          initialPromptTopic: course.title,
                          initialPrompt:
                              'Ninaendelea na ${course.title}. Nisaidie kuelewa somo linalofuata.',
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ExpertPanel(
                      onTap: () => AppNavigator.pushWhatsApp(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Lesson? _heroLesson(BuildContext context, Course course) {
  if (course.lessons.isEmpty) return null;

  for (final lesson in course.lessons) {
    final completed = lesson.isCompleted ||
        context.session.isLessonCompleted(lessonProgressKey(course, lesson));
    if (!completed) return lesson;
  }

  return course.lessons.first;
}

void _openLessonPreview(BuildContext context, Course course, Lesson lesson) {
  if (lesson.isPremium && !context.session.hasActiveSubscription) {
    AppNavigator.pushPaywall(context);
    return;
  }

  showAppModalSheet<void>(
    context: context,
    builder: (_) => LessonPreviewSheet(
      courseId: course.id,
      lessonId: lessonContentId(lesson),
      lessonProgressKey: lessonProgressKey(course, lesson),
      lesson: lesson,
      courseTitle: course.title,
    ),
  );
}
