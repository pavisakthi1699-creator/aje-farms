import 'package:aje_farms_mobile/src/app/app_dependencies.dart';
import 'package:aje_farms_mobile/src/app/app_navigator.dart';
import 'package:aje_farms_mobile/src/features/auth/auth_screen.dart';
import 'package:aje_farms_mobile/src/features/courses/course_detail_screen.dart';
import 'package:aje_farms_mobile/src/features/community/community_screen.dart';
import 'package:aje_farms_mobile/src/features/paywall/paywall_screen.dart';
import 'package:aje_farms_mobile/src/features/problem/problem_screen.dart';
import 'package:aje_farms_mobile/src/features/search/search_screen.dart';
import 'package:aje_farms_mobile/src/models/app_document.dart';
import 'package:aje_farms_mobile/src/models/course.dart';
import 'package:aje_farms_mobile/src/models/problem_category.dart';
import 'package:aje_farms_mobile/src/models/search_result.dart';
import 'package:aje_farms_mobile/src/repositories/learning_repository.dart';
import 'package:aje_farms_mobile/src/repositories/cached_app_repository.dart';
import 'package:aje_farms_mobile/src/services/search_service.dart';
import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/services/local_search_service.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:aje_farms_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/stub_auth_service.dart';

void main() {
  Future<void> pumpSearch(
    WidgetTester tester, {
    AppDependencies? dependencies,
    SearchScope scope = SearchScope.all,
    String? initialQuery,
    bool acceptCommunityTerms = false,
    String accountStatus = 'active',
  }) async {
    SharedPreferences.setMockInitialValues({});
    final session = AppSessionController();
    addTearDown(session.dispose);
    await session.signInWithEmail('learner@aje.test', role: 'learner');
    await session.syncAccountStatusFromAuthSession(
      AuthSession(
        email: 'learner@aje.test',
        role: 'learner',
        accountStatus: accountStatus,
        termsAcceptedVersion: acceptCommunityTerms ? currentTermsVersion : null,
      ),
    );
    await session.syncProfileFromAuthSession(
      AuthSession(
        email: 'learner@aje.test',
        termsAcceptedVersion: acceptCommunityTerms ? currentTermsVersion : null,
      ),
    );

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies ?? AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            onGenerateRoute: AppNavigator.onGenerateRoute,
            home: SearchScreen(
              initialScope: scope,
              initialQuery: initialQuery,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('searches learning content and opens a course', (tester) async {
    await pumpSearch(tester);

    expect(find.text('Tafuta'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nyanya');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Kilimo cha Nyanya'), findsOneWidget);
    await tester.tap(find.text('Kilimo cha Nyanya'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CourseDetailScreen), findsOneWidget);
  });

  testWidgets('starts search using normalized Unicode character count',
      (tester) async {
    const service = _FixedSearchService(
      SearchResult(
        kind: SearchResultKind.course,
        id: 'normalized-query',
        title: 'Matokeo ya Unicode',
        metadata: 'Kozi',
      ),
    );
    final demo = AppDependencies.demo();
    final dependencies = _withSearchService(demo, service);

    await pumpSearch(
      tester,
      dependencies: dependencies,
      initialQuery: 'ﬀ',
    );
    await tester.pump();

    expect(find.text('Matokeo ya Unicode'), findsOneWidget);
  });

  testWidgets('does not search a single non-BMP Unicode character',
      (tester) async {
    const service = _FixedSearchService(
      SearchResult(
        kind: SearchResultKind.course,
        id: 'single-code-point',
        title: 'Haipaswi kuonekana',
        metadata: 'Kozi',
      ),
    );
    final demo = AppDependencies.demo();
    final dependencies = _withSearchService(demo, service);

    await pumpSearch(
      tester,
      dependencies: dependencies,
      initialQuery: '𐐀',
    );
    await tester.pump();

    expect(find.text('Haipaswi kuonekana'), findsNothing);
    expect(find.text('Mada maarufu'), findsOneWidget);
  });

  testWidgets('premium search result cannot bypass the paywall',
      (tester) async {
    const service = _FixedSearchService(
      SearchResult(
        kind: SearchResultKind.lesson,
        id: 'premium-lesson',
        parentId: 'nyanya',
        title: 'Somo la kulipia',
        metadata: 'Somo',
        isPremium: true,
      ),
    );
    final demo = AppDependencies.demo();

    await pumpSearch(
      tester,
      dependencies: _withSearchService(demo, service),
      initialQuery: 'kulipia',
      accountStatus: 'pending_activation',
    );
    await tester.pump();
    await tester.tap(find.text('Somo la kulipia'));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.byType(CourseDetailScreen), findsNothing);
  });

  testWidgets(
      'authentication failure clears protected index even when sign-out fails',
      (tester) async {
    final demo = AppDependencies.demo();
    final cachedRepository = CachedAppRepository(
      learningSeed: demo.learningRepository,
      communitySeed: demo.communityRepository,
      subscriptionSeed: demo.subscriptionRepository,
    );
    final offlineService = LocalSearchService(
      learningRepository: cachedRepository,
      communityRepository: cachedRepository,
      cachedRepository: cachedRepository,
    );
    addTearDown(offlineService.dispose);
    final beforeClear = await offlineService.search(
      const SearchRequest(
        query: 'Kuchagua eneo la shamba',
        scope: SearchScope.learning,
      ),
    );
    expect(beforeClear.results, isNotEmpty);
    expect(offlineService.debugIndexedRecordCount, greaterThan(0));

    final dependencies = AppDependencies(
      learningRepository: cachedRepository,
      communityRepository: cachedRepository,
      subscriptionRepository: cachedRepository,
      mwalimuAiService: demo.mwalimuAiService,
      authService: _FailingSignOutAuthService(),
      catalogService: demo.catalogService,
      adminService: demo.adminService,
      communityService: demo.communityService,
      learningProgressService: demo.learningProgressService,
      notificationService: demo.notificationService,
      paymentService: demo.paymentService,
      searchService: const _ThrowingSearchService(401),
      offlineSearchService: offlineService,
      refreshCatalog: demo.refreshCatalog,
      refreshListenable: cachedRepository,
    );

    await pumpSearch(tester, dependencies: dependencies);
    await tester.enterText(find.byType(TextField), 'Kuchagua eneo la shamba');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(cachedRepository.courses, isEmpty);
    expect(cachedRepository.documents, isEmpty);
    expect(offlineService.debugIndexedRecordCount, 0);
    final afterClear = await offlineService.search(
      const SearchRequest(
        query: 'Kuchagua eneo la shamba',
        scope: SearchScope.learning,
      ),
    );
    expect(afterClear.results, isEmpty);
  });

  testWidgets('lesson result targets and scrolls to its course lesson',
      (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'Kuchagua eneo la shamba');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await tester.tap(find.text('Kuchagua eneo la shamba').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final detail = tester.widget<CourseDetailScreen>(
      find.byType(CourseDetailScreen),
    );
    expect(detail.initialLessonId, 'kuchagua-eneo-la-shamba');
  });

  testWidgets('problem result opens the problem flow preselected',
      (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'Magonjwa ya mimea');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await tester.tap(find.text('Magonjwa ya mimea').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ProblemScreen), findsOneWidget);
    expect(find.text('Changamoto uliyochagua'), findsOneWidget);
  });

  testWidgets('community result opens the existing discussion', (tester) async {
    await pumpSearch(
      tester,
      scope: SearchScope.community,
      acceptCommunityTerms: true,
    );
    await tester.enterText(find.byType(TextField), 'Karibu');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await tester.tap(find.textContaining('Karibu kwenye jamii').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CommunityPostDetailScreen), findsOneWidget);
  });

  testWidgets('community results stay hidden until terms are accepted',
      (tester) async {
    const service = _FixedSearchService(
      SearchResult(
        kind: SearchResultKind.community,
        id: 'post-without-terms',
        title: 'Mjadala wa siri',
        metadata: 'Jamii',
      ),
    );
    final demo = AppDependencies.demo();
    final dependencies = AppDependencies(
      learningRepository: demo.learningRepository,
      communityRepository: demo.communityRepository,
      subscriptionRepository: demo.subscriptionRepository,
      mwalimuAiService: demo.mwalimuAiService,
      authService: demo.authService,
      catalogService: demo.catalogService,
      adminService: demo.adminService,
      communityService: demo.communityService,
      learningProgressService: demo.learningProgressService,
      notificationService: demo.notificationService,
      paymentService: demo.paymentService,
      searchService: service,
      offlineSearchService: service,
      refreshCatalog: demo.refreshCatalog,
    );

    await pumpSearch(
      tester,
      dependencies: dependencies,
      scope: SearchScope.community,
      initialQuery: 'mjadala',
    );
    await tester.pump();

    expect(find.text('Mjadala wa siri'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Jamii'), findsNothing);
  });

  testWidgets('unaccepted community terms exclude posts before top-K ranking',
      (tester) async {
    final service = _ScopeAwareSearchService();
    final demo = AppDependencies.demo();

    await pumpSearch(
      tester,
      dependencies: _withSearchService(demo, service),
      initialQuery: 'nyanya',
    );
    await tester.pump();

    expect(service.lastScope, SearchScope.learning);
    expect(find.text('Kozi inayoruhusiwa'), findsOneWidget);
    expect(find.textContaining('Mjadala'), findsNothing);
  });

  testWidgets('document without a safe URL falls back to its parent course',
      (tester) async {
    final demo = AppDependencies.demo();
    final learning = _DocumentLearningRepository(demo.learningRepository);
    const service = _FixedSearchService(
      SearchResult(
        kind: SearchResultKind.document,
        id: 'guide',
        parentId: 'pasheni',
        title: 'Mwongozo wa Pasheni',
        metadata: 'PDF',
      ),
    );
    final dependencies = AppDependencies(
      learningRepository: learning,
      communityRepository: demo.communityRepository,
      subscriptionRepository: demo.subscriptionRepository,
      mwalimuAiService: demo.mwalimuAiService,
      authService: demo.authService,
      catalogService: demo.catalogService,
      adminService: demo.adminService,
      communityService: demo.communityService,
      learningProgressService: demo.learningProgressService,
      notificationService: demo.notificationService,
      paymentService: demo.paymentService,
      searchService: service,
      offlineSearchService: service,
      refreshCatalog: demo.refreshCatalog,
    );
    await pumpSearch(
      tester,
      dependencies: dependencies,
      scope: SearchScope.documents,
      initialQuery: 'mwongozo',
    );
    await tester.pump();

    await tester.tap(find.text('Mwongozo wa Pasheni'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CourseDetailScreen), findsOneWidget);
  });
}

AppDependencies _withSearchService(
  AppDependencies demo,
  SearchService service,
) {
  return AppDependencies(
    learningRepository: demo.learningRepository,
    communityRepository: demo.communityRepository,
    subscriptionRepository: demo.subscriptionRepository,
    mwalimuAiService: demo.mwalimuAiService,
    authService: demo.authService,
    catalogService: demo.catalogService,
    adminService: demo.adminService,
    communityService: demo.communityService,
    learningProgressService: demo.learningProgressService,
    notificationService: demo.notificationService,
    paymentService: demo.paymentService,
    searchService: service,
    offlineSearchService: service,
    refreshCatalog: demo.refreshCatalog,
  );
}

class _FixedSearchService implements SearchService {
  const _FixedSearchService(this.result);

  final SearchResult result;

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    return SearchResponse(
      query: normalizeSearchText(request.query),
      scope: request.scope,
      results: [result],
      truncated: false,
    );
  }
}

class _ThrowingSearchService implements SearchService {
  const _ThrowingSearchService(this.statusCode);

  final int statusCode;

  @override
  Future<SearchResponse> search(SearchRequest request) {
    throw SearchException('Imeshindikana', statusCode: statusCode);
  }
}

class _ScopeAwareSearchService implements SearchService {
  SearchScope? lastScope;

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    lastScope = request.scope;
    return SearchResponse(
      query: normalizeSearchText(request.query),
      scope: request.scope,
      results: request.scope == SearchScope.learning
          ? const [
              SearchResult(
                kind: SearchResultKind.course,
                id: 'allowed-course',
                title: 'Kozi inayoruhusiwa',
                metadata: 'Kozi',
              ),
            ]
          : [
              for (var index = 0; index < 20; index += 1)
                SearchResult(
                  kind: SearchResultKind.community,
                  id: 'post-$index',
                  title: 'Mjadala $index',
                  metadata: 'Jamii',
                ),
            ],
      truncated: false,
    );
  }
}

class _FailingSignOutAuthService extends StubAuthService {
  _FailingSignOutAuthService() : super('active');

  @override
  Future<void> signOut() => throw const AuthException('sign-out failed');
}

class _DocumentLearningRepository implements LearningRepository {
  const _DocumentLearningRepository(this.delegate);

  final LearningRepository delegate;

  @override
  List<Course> get courses => delegate.courses;

  @override
  List<AppDocument> get documents => const [
        AppDocument(
          id: 'guide',
          title: 'Mwongozo wa Pasheni',
          courseId: 'pasheni',
          courseTitle: 'Kilimo cha Pasheni',
          description: 'Mwongozo wa shamba',
          type: 'PDF',
          sizeLabel: '1 MB',
        ),
      ];

  @override
  Course? get featuredCourse => delegate.featuredCourse;

  @override
  List<String> get homeTopics => delegate.homeTopics;

  @override
  List<ProblemCategory> get problemCategories => delegate.problemCategories;

  @override
  Course? get suggestedCourse => delegate.suggestedCourse;
}
