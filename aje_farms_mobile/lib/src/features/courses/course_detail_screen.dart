// ignore_for_file: use_key_in_widget_constructors

import 'package:url_launcher/url_launcher.dart';

import "../../ui.dart";

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    required this.course,
    this.initialLessonId,
    super.key,
  });

  final Course course;
  final String? initialLessonId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _targetLessonKey = GlobalKey();
  bool _scheduledTargetScroll = false;

  void _scheduleTargetScroll() {
    if (_scheduledTargetScroll || widget.initialLessonId == null) return;
    _scheduledTargetScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _targetLessonKey.currentContext;
      if (!mounted || targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: AppMotion.durationOf(context, AppMotion.standard),
        curve: AppMotion.standardCurve,
        alignment: 0.25,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = context.dependencies.learningRepository.courses
        .where((candidate) => candidate.id == widget.course.id)
        .firstOrNull;
    final currentCourse = course ?? widget.course;
    final heroLesson = _heroLesson(context, currentCourse);
    _scheduleTargetScroll();

    return Scaffold(
      body: CustomScrollView(
        key: AppPageStorage.courseDetail(currentCourse.id),
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
                currentCourse.title,
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
                  NetworkPhoto(url: currentCourse.imageUrl),
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
                                _openLessonPreview(
                                  context,
                                  currentCourse,
                                  heroLesson,
                                );
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
                                  lessonHeroIcon(heroLesson),
                                  color: context.colors.onPrimary,
                                  size: heroLesson.type == LessonType.video
                                      ? 46
                                      : 38,
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
                    CourseProgressSummary(course: currentCourse),
                    if (currentCourse.introVideoUrl != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.play_circle_fill_outlined,
                              color: context.colors.primary),
                          title: const Text('Tazama video fupi ya utangulizi'),
                          subtitle: const Text('Utangulizi wa kozi hii'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () async {
                            final uri =
                                Uri.tryParse(currentCourse.introVideoUrl!);
                            if (uri == null ||
                                !await launchUrl(uri,
                                    mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                showErrorSnack(
                                    context, 'Imeshindikana kufungua video.');
                              }
                            }
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentCourse.badge,
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
                              currentCourse.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              currentCourse.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Malengo ya Somo:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...currentCourse.outcomes.map(
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
                    ...currentCourse.lessons.map((lesson) {
                      final isTarget =
                          lessonContentId(lesson) == widget.initialLessonId;
                      final tile = LessonTile(
                        lesson: lesson,
                        isCompleted: lesson.isCompleted ||
                            context.session.isLessonCompleted(
                              lessonProgressKey(currentCourse, lesson),
                            ),
                        onTap: () =>
                            _openLessonPreview(context, currentCourse, lesson),
                      );
                      if (!isTarget) return tile;
                      return Container(
                        key: _targetLessonKey,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.colors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Semantics(
                          liveRegion: true,
                          label: 'Somo lililopatikana: ${lesson.title}',
                          child: tile,
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xl),
                    AskAiPanel(
                      courseTitle: currentCourse.title,
                      onTap: () {
                        AppNavigator.pushAiChat(
                          context,
                          initialPromptTopic: currentCourse.title,
                          initialPrompt:
                              'Ninaendelea na ${currentCourse.title}. Nisaidie kuelewa somo linalofuata.',
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

IconData lessonHeroIcon(Lesson lesson) {
  return lesson.type == LessonType.video
      ? Icons.play_arrow_rounded
      : Icons.menu_book_rounded;
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
  if (lesson.isPremium && !context.session.hasActiveAccess) {
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
