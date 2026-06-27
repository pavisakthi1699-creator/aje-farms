part of '../../app.dart';

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
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
                  _NetworkPhoto(url: course.imageUrl),
                  Positioned(
                      left: 16, top: 16, child: _Pill(label: course.badge)),
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

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor:
              lesson.isPremium ? Colors.grey.shade100 : AppColors.blue,
          child: Icon(lesson.isPremium ? Icons.lock_outline : lesson.type.icon,
              color: lesson.isPremium ? Colors.grey : AppColors.primary),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${lesson.type.label} - ${lesson.meta}'),
        trailing:
            Icon(lesson.isPremium ? Icons.lock_outline : Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AskAiPanel extends StatelessWidget {
  const _AskAiPanel({required this.courseTitle, required this.onTap});

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
