part of '../../app.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course.title),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkPhoto(url: course.imageUrl),
                  Container(color: Colors.black.withValues(alpha: 0.32)),
                  const Center(
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.play_arrow, color: Colors.white, size: 46),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.badge.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(course.title,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          Text(course.description),
                          const SizedBox(height: 18),
                          Text('Malengo ya Somo:',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          ...course.outcomes.map(
                            (outcome) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(outcome)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Masomo',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...course.lessons.map(
                    (lesson) => _LessonTile(
                      lesson: lesson,
                      onTap: () {
                        if (lesson.isPremium) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PaywallScreen()),
                          );
                        } else {
                          _showSnack(
                              context, '${lesson.type.label}: ${lesson.title}');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AskAiPanel(
                    courseTitle: course.title,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              AiChatScreen(initialPromptTopic: course.title)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ExpertPanel(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const WhatsAppEscalationScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
