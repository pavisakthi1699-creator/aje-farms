import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aje_farms_mobile/src/app.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';

import 'support/stub_auth_service.dart';

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<AppSessionController> signedInSession({String? accountStatus}) async {
    final session = AppSessionController();
    await session.signInWithEmail('mkulima@aje.test', role: 'learner');
    if (accountStatus != null) {
      await session.syncAccountStatusFromAuthSession(
        AuthSession(email: 'mkulima@aje.test', accountStatus: accountStatus),
      );
    }
    return session;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
      'a registered but unapproved learner is held at the Swahili pending '
      'screen instead of the learner shell', (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'pending_activation');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('pending_activation'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hali ya Akaunti'), findsOneWidget);
    expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);
    expect(
      find.text(
        'Umesajiliwa. Timu ya AJE Farms itathibitisha akaunti yako '
        'ili kufungua mafunzo.',
      ),
      findsOneWidget,
    );

    // The shell itself must not be behind the wall: no tabs, no dashboard.
    expect(find.textContaining('Karibu'), findsNothing);
    expect(find.text('Nyumbani'), findsNothing);
    expect(find.text('Mafunzo'), findsNothing);
    expect(find.text('Uliza AI'), findsNothing);
  });

  testWidgets('a suspended account is told so, in Swahili',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'suspended');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('suspended'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Akaunti yako imesitishwa'), findsOneWidget);
    expect(find.textContaining('Karibu'), findsNothing);
  });

  testWidgets('an approved learner still reaches the shell',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'active');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('active'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Karibu'), findsOneWidget);
    expect(find.text('Hali ya Akaunti'), findsNothing);
  });

  testWidgets('approval mid-session opens the app without a restart',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = _PausingSessionController();
    await session.signInWithEmail('mkulima@aje.test', role: 'learner');
    await session.syncAccountStatusFromAuthSession(
      const AuthSession(
        email: 'mkulima@aje.test',
        accountStatus: 'pending_activation',
      ),
    );
    final authService = StubAuthService('pending_activation');
    var catalogRefreshes = 0;

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: authService,
          refreshCatalog: () async => catalogRefreshes += 1,
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);
    final refreshesBeforeApproval = catalogRefreshes;

    authService.accountStatus = 'active';
    await tester.ensureVisible(find.text('Onyesha Hali Upya'));
    await tester.tap(find.text('Onyesha Hali Upya'));
    await session.waitUntilActiveSyncPauses;
    await tester.pump();
    session.resumeActiveSync();
    await tester.pumpAndSettle();

    expect(find.textContaining('Karibu'), findsWidgets);
    expect(
      catalogRefreshes,
      refreshesBeforeApproval + 1,
      reason: 'Unlocking must replace the locked catalog before opening.',
    );
  });

  testWidgets('an open course detail follows a refreshed catalog version',
      (tester) async {
    const seed = DemoAppRepository();
    final repository = CachedAppRepository(
      learningSeed: seed,
      communitySeed: seed,
      subscriptionSeed: seed,
    );
    final original = repository.courses.first;
    final updated = Course(
      id: original.id,
      title: 'Jina Jipya la Kozi',
      description: 'Maudhui mapya yaliyotoka kwenye katalogi.',
      badge: original.badge,
      icon: original.icon,
      progress: original.progress,
      imageUrl: original.imageUrl,
      outcomes: original.outcomes,
      lessons: original.lessons,
    );
    final catalogService = _SingleCourseCatalogService(updated);
    final demo = AppDependencies.demo();
    final dependencies = AppDependencies(
      learningRepository: repository,
      communityRepository: repository,
      subscriptionRepository: repository,
      mwalimuAiService: demo.mwalimuAiService,
      authService: demo.authService,
      catalogService: catalogService,
      adminService: demo.adminService,
      communityService: demo.communityService,
      learningProgressService: demo.learningProgressService,
      notificationService: demo.notificationService,
      paymentService: demo.paymentService,
      refreshCatalog: () => repository.refresh(catalogService),
      refreshListenable: repository,
    );
    final session = AppSessionController();
    addTearDown(session.dispose);
    await session.signInWithEmail('mkulima@aje.test', role: 'learner');
    await session.syncAccountStatusFromAuthSession(
      const AuthSession(
        email: 'mkulima@aje.test',
        role: 'learner',
        accountStatus: 'active',
      ),
    );

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: AppSessionScope(
          controller: session,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: CourseDetailScreen(course: original),
          ),
        ),
      ),
    );
    expect(find.text(original.title), findsWidgets);

    await dependencies.refreshCatalog();
    await tester.pump();

    expect(find.text('Jina Jipya la Kozi'), findsWidgets);
    expect(
      find.text('Maudhui mapya yaliyotoka kwenye katalogi.'),
      findsOneWidget,
    );
    expect(find.text(original.title), findsNothing);
  });
}

class _PausingSessionController extends AppSessionController {
  final _activeSyncPaused = Completer<void>();
  final _resumeActiveSync = Completer<void>();

  Future<void> get waitUntilActiveSyncPauses => _activeSyncPaused.future;

  void resumeActiveSync() => _resumeActiveSync.complete();

  @override
  Future<void> syncAccountStatusFromAuthSession(AuthSession session) async {
    await super.syncAccountStatusFromAuthSession(session);
    if (session.accountStatus == 'active') {
      _activeSyncPaused.complete();
      await _resumeActiveSync.future;
    }
  }
}

class _SingleCourseCatalogService implements CatalogService {
  const _SingleCourseCatalogService(this.course);

  final Course course;

  @override
  Future<String> lessonVideoUrl(String lessonId) async =>
      'https://example.test/v';

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    const seed = DemoAppRepository();
    return CatalogSnapshot(
      courses: [course],
      documents: seed.documents,
      problemCategories: seed.problemCategories,
      communityPosts: seed.posts,
      plans: seed.plans,
    );
  }
}
