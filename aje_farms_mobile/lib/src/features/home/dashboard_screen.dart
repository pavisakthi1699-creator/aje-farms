// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCourse = context.dependencies.learningRepository.featuredCourse;

    return Scaffold(
      appBar: AppBar(
        title: const BrandHeader(compact: true),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: CircleIconButton(
              icon: Icons.notifications_none,
              tooltip: 'Arifa',
              semanticLabel: 'Arifa',
              onPressed: () => AppNavigator.pushNotifications(context),
            ),
          ),
        ],
      ),
      body: AppLayout(
        child: ListView(
          key: AppPageStorage.dashboard,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              context.session.state.dashboardGreeting,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Endeleza shamba lako leo',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            const TrialStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            HeroActionCard(
              onTap: () => AppNavigator.pushProblem(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: MiniActionCard(
                    color: context.colors.mint,
                    icon: Icons.smart_toy_outlined,
                    title: 'Uliza AI',
                    subtitle: 'Andaa swali lako',
                    onTap: () {
                      context.switchMainShellTab(MainShellTab.aiChat);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MiniActionCard(
                    color: context.colors.charcoal,
                    foreground: context.colors.onPrimary,
                    icon: Icons.workspace_premium_outlined,
                    // Not a package picker: access is granted by staff, so
                    // this only opens the account's current status.
                    title: 'Uanachama',
                    subtitle: 'Angalia hali yako',
                    onTap: () => AppNavigator.pushPaywall(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(
              title: 'Endelea Kujifunza',
              actionIcon: Icons.add,
              onAction: () {
                context.switchMainShellTab(MainShellTab.courses);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            if (activeCourse == null)
              const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Mafunzo yanaandaliwa',
                body: 'Hakuna kozi iliyokamilisha ukaguzi wa vyanzo kwa sasa.',
              )
            else
              CourseProgressCard(
                key: ValueKey('dashboard-course-${activeCourse.id}'),
                course: activeCourse,
                onTap: () => AppNavigator.pushCourse(context, activeCourse),
              ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Mada za Kujifunza',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            const TrendingTopics(),
            const SizedBox(height: AppSpacing.xxl),
            CommunityTeaser(
              onTap: () {
                context.switchMainShellTab(MainShellTab.community);
              },
            ),
          ],
        ),
      ),
    );
  }
}
