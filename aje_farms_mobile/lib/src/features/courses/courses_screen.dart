// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  Future<void> _handleRefresh(BuildContext context) async {
    await context.dependencies.refreshCatalog();
    if (!context.mounted) return;
    showSnack(context, 'Maudhui yamesasishwa.');
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = context.dependencies;
    final refreshListenable = dependencies.refreshListenable ?? kIdleListenable;

    return Scaffold(
      appBar: AppBar(title: const Text('Mafunzo')),
      body: AppLayout(
        child: ListenableBuilder(
          listenable: refreshListenable,
          builder: (context, _) {
            final cached = dependencies.cachedRepository;
            if (cached?.isInitialLoadPending == true) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: const [CourseCatalogSkeleton()],
              );
            }

            final courses = dependencies.learningRepository.courses;
            return FadeInContent(
              child: RefreshIndicator(
                onRefresh: () => _handleRefresh(context),
                child: courses.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        children: [
                          EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'Hakuna kozi bado',
                            body:
                                'Hakuna maudhui ya mafunzo yaliyopatikana kwa sasa. Vuta chini kusasisha.',
                            actionLabel: 'Sasisha',
                            onAction: () => _handleRefresh(context),
                          ),
                        ],
                      )
                    : CustomScrollView(
                        key: AppPageStorage.courses,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Text(
                                  'Chagua Mada.\nJifunze Kilimo.',
                                  style:
                                      Theme.of(context).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Chagua kozi hapa chini ili kuongeza tija kwenye shamba lako leo.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                LearningSummaryCard(courses: courses),
                                const SizedBox(height: AppSpacing.lg),
                              ]),
                            ),
                          ),
                          AdaptiveCatalogSliver(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              0,
                              AppSpacing.xl,
                              AppSpacing.xl,
                            ),
                            itemCount: courses.length,
                            itemBuilder: (context, index) {
                              return CourseCard(course: courses[index]);
                            },
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
