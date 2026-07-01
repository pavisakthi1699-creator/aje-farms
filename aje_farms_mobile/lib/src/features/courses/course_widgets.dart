// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class LearningSummaryCard extends StatelessWidget {
  const LearningSummaryCard({required this.courses});

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final completedLessons = courses
        .expand((course) => course.lessons)
        .where((lesson) => lesson.isCompleted)
        .length;
    final totalLessons =
        courses.expand((course) => course.lessons).toList().length;

    return Card(
      color: AppColors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.menu_book_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maktaba yako',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '$completedLessons kati ya $totalLessons yamekamilika kwenye kozi za mfano.',
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
          session.isLessonCompleted('${course.id}:${lesson.title}');
    }).length;
    final total = course.lessons.length;
    final hasPremium = course.lessons.any((lesson) => lesson.isPremium);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(url: course.imageUrl),
                  Positioned(
                      left: 16, top: 16, child: Pill(label: course.badge)),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$completed/$total masomo',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(course.description),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: course.progress),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      course.progress > 0
                          ? '${(course.progress * 100).round()}% imekamilika'
                          : 'Tayari kuanza',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (hasPremium)
                      const Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16, color: AppColors.muted),
                          SizedBox(width: 4),
                          Text('Premium',
                              style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(course: course)),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Anza Kujifunza'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.text),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AiChatScreen(
                                  initialPromptTopic: course.title)),
                        ),
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: const Text('Uliza AI'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const WhatsAppEscalationScreen()),
                        ),
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
    );
  }
}

class CourseProgressSummary extends StatelessWidget {
  const CourseProgressSummary({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final completed =
        course.lessons.where((lesson) => lesson.isCompleted).length;
    final total = course.lessons.length;

    return Card(
      color: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Mwendelezo wa kozi',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('$completed/$total',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: completed / total),
            const SizedBox(height: 10),
            Text(
              completed == 0
                  ? 'Anza na somo la kwanza kisha fuata mpangilio wa masomo.'
                  : 'Masomo ya msingi yamekamilika. Endelea na jaribio au uliza AI swali la kozi.',
            ),
          ],
        ),
      ),
    );
  }
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
    final statusColor = isCompleted ? AppColors.primary : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor:
              lesson.isPremium ? Colors.grey.shade100 : AppColors.blue,
          child: Icon(
            lesson.isPremium
                ? Icons.lock_outline
                : isCompleted
                    ? Icons.check_circle
                    : lesson.type.icon,
            color: lesson.isPremium ? Colors.grey : AppColors.primary,
          ),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${lesson.type.label} - ${lesson.meta}'),
            const SizedBox(height: 2),
            Text(
              lesson.isPremium
                  ? 'Fungua premium kuendelea'
                  : isCompleted
                      ? 'Umekamilisha'
                      : 'Bado hujaanza',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        trailing:
            Icon(lesson.isPremium ? Icons.lock_outline : Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class LessonPreviewSheet extends StatelessWidget {
  const LessonPreviewSheet({
    required this.lessonId,
    required this.lesson,
    required this.courseTitle,
  });

  final String lessonId;
  final Lesson lesson;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.blue,
                  child: Icon(lesson.type.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('$courseTitle - ${lesson.type.label}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(lesson.description),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                await context.session.markLessonCompleted(lessonId);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showSnack(context, '${lesson.type.label}: ${lesson.title}');
              },
              icon: Icon(lesson.type.icon),
              label: const Text('Fungua Somo la Mfano'),
            ),
          ],
        ),
      ),
    );
  }
}

class AskAiPanel extends StatelessWidget {
  const AskAiPanel({required this.courseTitle, required this.onTap});

  final String courseTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Una swali gani?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Mwalimu AI yuko tayari kujibu maswali kuhusu $courseTitle'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Uliza AI Sasa'),
            ),
          ],
        ),
      ),
    );
  }
}
