part of '../../app.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCourse = _demoRepository.featuredCourse;

    return Scaffold(
      appBar: AppBar(
        title: const _BrandHeader(compact: true),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const Text(
            'Karibu, Mkulima',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Endeleza shamba lako leo',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          const _TrialStatusCard(),
          const SizedBox(height: 16),
          _HeroActionCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProblemScreen()),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniActionCard(
                  color: AppColors.mint,
                  icon: Icons.smart_toy_outlined,
                  title: 'Uliza AI',
                  subtitle: 'Majibu ya Papo',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniActionCard(
                  color: AppColors.text,
                  foreground: Colors.white,
                  icon: Icons.star,
                  title: 'Premium',
                  subtitle: 'Fungua Soko',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Endelea Kujifunza',
            actionIcon: Icons.add,
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoursesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _CourseProgressCard(
            key: ValueKey('dashboard-course-${activeCourse.id}'),
            course: activeCourse,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(course: activeCourse)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Mada Zinazovuma',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _TrendingTopics(),
          const SizedBox(height: 24),
          _CommunityTeaser(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommunityScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
