import 'package:aje_farms_mobile/src/app.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves a single course so the admin content editor is reachable in tests.
class _OneCourseAdminService extends LocalAdminService {
  const _OneCourseAdminService();

  @override
  Future<List<AdminContentCourseRecord>> listContentCourses() async {
    return [
      AdminContentCourseRecord(
        id: 'course-1',
        status: 'draft',
        updatedAt: DateTime(2026),
        course: const Course(
          id: 'course-1',
          title: 'Kilimo cha Nyanya',
          description: 'Mwongozo wa nyanya.',
          badge: 'Msingi',
          icon: Icons.eco_outlined,
          progress: 0,
          imageUrl: '',
          outcomes: ['Msingi'],
          lessons: [
            Lesson(
              id: 'lesson-1',
              moduleId: 'module-1',
              moduleTitle: 'Msingi',
              title: 'Kuandaa kitalu',
              type: LessonType.reading,
              meta: 'Dakika 5',
              description: 'Andaa kitalu salama.',
              durationMinutes: 5,
              isLearnerVisible: false,
              readinessReasons: [
                'Kozi bado haijachapishwa.',
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class _RecordingCourseAdminService extends _OneCourseAdminService {
  Course? savedCourse;
  String? savedStatus;
  DateTime? savedBaseUpdatedAt;
  bool? savedCreateOnly;

  @override
  Future<AdminContentCourseRecord> upsertContentCourse({
    required Course course,
    required String status,
    DateTime? baseUpdatedAt,
    bool createOnly = false,
  }) async {
    savedCourse = course;
    savedStatus = status;
    savedBaseUpdatedAt = baseUpdatedAt;
    savedCreateOnly = createOnly;
    return AdminContentCourseRecord(
      id: course.id,
      status: 'draft',
      course: course,
      updatedAt: DateTime(2026, 7, 26),
    );
  }
}

/// Covers the accessibility, validation, and destructive-action guarantees that
/// are easy to regress because nothing in the happy path exercises them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapAuth() {
    return AppDependenciesScope(
      dependencies: AppDependencies.demo(),
      child: AppSessionScope(
        controller: AppSessionController(),
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
  }

  // The email/password + forgot-password form doesn't fit the default
  // 800x600 test surface, so the submit button never becomes hit-testable.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('auth inline validation', () {
    testWidgets('rejects an invalid email inline rather than via snack bar',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, 'not-an-email');
      await tester.ensureVisible(find.text('Ingia Sasa'));
      await tester.tap(find.text('Ingia Sasa'));
      await tester.pumpAndSettle();

      expect(find.text('Weka barua pepe sahihi.'), findsOneWidget);
      // No navigation should have happened, i.e. sign-in was not attempted.
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('rejects a short password', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(
          find.byType(EditableText).at(0), 'mkulima@aje.test');
      await tester.enterText(find.byType(EditableText).at(1), '123');
      await tester.ensureVisible(find.text('Ingia Sasa'));
      await tester.tap(find.text('Ingia Sasa'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenosiri linahitajika kuwa na angalau tarakimu 6.'),
        findsOneWidget,
      );
    });

    testWidgets('clears the inline error once the user edits the field',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, 'not-an-email');
      await tester.ensureVisible(find.text('Ingia Sasa'));
      await tester.tap(find.text('Ingia Sasa'));
      await tester.pumpAndSettle();
      expect(find.text('Weka barua pepe sahihi.'), findsOneWidget);

      await tester.enterText(
          find.byType(EditableText).first, 'mkulima@aje.test');
      // InputDecorator fades the error out, so settle past the animation.
      await tester.pumpAndSettle();

      expect(find.text('Weka barua pepe sahihi.'), findsNothing);
    });

    testWidgets('offers a forgot-password affordance in sign-in mode',
        (tester) async {
      await tester.pumpWidget(wrapAuth());

      expect(find.text('Umesahau nenosiri?'), findsOneWidget);
    });

    testWidgets('email and password fields declare autofill hints',
        (tester) async {
      await tester.pumpWidget(wrapAuth());

      final hints = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.autofillHints)
          .whereType<Iterable<String>>()
          .expand((hint) => hint)
          .toList();

      expect(hints, contains(AutofillHints.email));
      expect(hints, contains(AutofillHints.password));
    });
  });

  group('destructive actions require confirmation', () {
    Future<void> openProfile(
      WidgetTester tester,
      AppSessionController session, {
      AppDependencies? dependencies,
    }) async {
      await tester.pumpWidget(
        AjeFarmsApp(
          dependencies: dependencies ?? AppDependencies.demo(),
          sessionController: session,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Akaunti'));
      await tester.pumpAndSettle();
    }

    testWidgets('sign out asks first and stays signed in when cancelled',
        (tester) async {
      final session = AppSessionController();
      await session.signInWithEmail('learner@aje.test', role: 'learner');
      await openProfile(tester, session);

      await tester.scrollUntilVisible(
        find.text('Ondoka kwenye Akaunti'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ondoka kwenye Akaunti'));
      await tester.pumpAndSettle();

      expect(find.text('Ondoka kwenye akaunti?'), findsOneWidget);

      await tester.tap(find.text('Ghairi'));
      await tester.pumpAndSettle();

      expect(session.isSignedIn, isTrue);
    });

    testWidgets('sign out proceeds when confirmed', (tester) async {
      final session = AppSessionController();
      await session.signInWithEmail('learner@aje.test', role: 'learner');
      const seed = DemoAppRepository();
      final cachedRepository = CachedAppRepository(
        learningSeed: seed,
        communitySeed: seed,
        subscriptionSeed: seed,
      );
      await cachedRepository.refresh(const _DemoSnapshotCatalogService());
      final demo = AppDependencies.demo();
      final dependencies = AppDependencies(
        learningRepository: cachedRepository,
        communityRepository: cachedRepository,
        subscriptionRepository: cachedRepository,
        mwalimuAiService: demo.mwalimuAiService,
        authService: demo.authService,
        catalogService: demo.catalogService,
        adminService: demo.adminService,
        communityService: demo.communityService,
        learningProgressService: demo.learningProgressService,
        notificationService: demo.notificationService,
        paymentService: demo.paymentService,
        refreshCatalog: () async {},
        refreshListenable: cachedRepository,
      );
      await openProfile(tester, session, dependencies: dependencies);

      expect(cachedRepository.courses, isNotEmpty);

      await tester.scrollUntilVisible(
        find.text('Ondoka kwenye Akaunti'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ondoka kwenye Akaunti'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ondoka'));
      await tester.pumpAndSettle();

      expect(session.isSignedIn, isFalse);
      expect(cachedRepository.courses, isEmpty);
      expect(cachedRepository.documents, isEmpty);
    });
  });

  group('admin dashboard', () {
    /// Opens the admin dashboard with [adminService] backing it.
    Future<void> openAdminDashboard(
      WidgetTester tester, {
      required AdminService adminService,
    }) async {
      final session = AppSessionController();
      await session.signInWithEmail('admin@aje.test', role: 'admin');

      final demo = AppDependencies.demo();
      await tester.pumpWidget(
        AjeFarmsApp(
          dependencies: AppDependencies(
            learningRepository: demo.learningRepository,
            communityRepository: demo.communityRepository,
            subscriptionRepository: demo.subscriptionRepository,
            mwalimuAiService: demo.mwalimuAiService,
            authService: demo.authService,
            catalogService: demo.catalogService,
            adminService: adminService,
            communityService: demo.communityService,
            learningProgressService: demo.learningProgressService,
            notificationService: demo.notificationService,
            paymentService: demo.paymentService,
            refreshCatalog: demo.refreshCatalog,
          ),
          sessionController: session,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Akaunti'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dashibodi ya Admin'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashibodi ya Admin'));
      await tester.pumpAndSettle();
    }

    testWidgets('content tab loads instead of erroring on mount',
        (tester) async {
      // Regression: the tabs used to kick off their initial load from
      // initState, which reads an InheritedWidget too early. The resulting
      // throw was swallowed by a generic catch, so every tab rendered a
      // permanent "failed to load" state and no admin data was ever shown.
      await openAdminDashboard(
        tester,
        adminService: const _OneCourseAdminService(),
      );

      expect(
          find.text('Imeshindikana kupakia content ya admin.'), findsNothing);
      expect(find.text('Kilimo cha Nyanya'), findsOneWidget);
    });

    testWidgets('moderation and users tabs load instead of erroring',
        (tester) async {
      await openAdminDashboard(
        tester,
        adminService: const _OneCourseAdminService(),
      );

      await tester.tap(find.text('Usimamizi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Imeshindikana kupakia moderation reports.'),
        findsNothing,
      );
      // Empty queue is the correct outcome for the stub, not a load failure.
      expect(find.text('Hakuna ripoti'), findsOneWidget);

      await tester.tap(find.text('Watumiaji'));
      await tester.pumpAndSettle();
      expect(
        find.text('Imeshindikana kupakia user monitoring.'),
        findsNothing,
      );
    });

    testWidgets('empty title shows an inline error instead of a silent no-op',
        (tester) async {
      await openAdminDashboard(
        tester,
        adminService: const _OneCourseAdminService(),
      );

      await tester.tap(find.text('Hariri maudhui na mtaala'));
      await tester.pumpAndSettle();

      // Clear the pre-filled title, then attempt to save.
      await tester.enterText(find.byType(EditableText).first, '');
      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi rasimu'));
      await tester.pumpAndSettle();

      expect(find.text('Jina haliwezi kuwa tupu.'), findsOneWidget);
      // The editor must stay open so the admin can correct the title.
      expect(find.text('Hariri mtaala'), findsOneWidget);
    });

    testWidgets('course editor exposes the complete curriculum fields',
        (tester) async {
      await openAdminDashboard(
        tester,
        adminService: const _OneCourseAdminService(),
      );

      await tester.tap(find.text('Hariri maudhui na mtaala'));
      await tester.pumpAndSettle();

      expect(find.text('Maelezo ya kozi'), findsOneWidget);
      expect(find.text('Sehemu na masomo'), findsOneWidget);
      expect(find.text('Kuandaa kitalu'), findsAtLeastNWidgets(1));

      expect(find.text('Jina la sehemu'), findsOneWidget);
      expect(find.text('Jina la somo'), findsOneWidget);
      expect(find.text('Muda (dakika)'), findsOneWidget);
      expect(find.text('Maandishi ya somo'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ongeza somo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ongeza somo'), findsOneWidget);
    });

    testWidgets('admin can create a complete new course curriculum',
        (tester) async {
      final service = _RecordingCourseAdminService();
      await openAdminDashboard(tester, adminService: service);

      await tester.tap(find.text('Ongeza kozi na mtaala'));
      await tester.pumpAndSettle();

      expect(find.text('Kozi mpya'), findsOneWidget);
      expect(find.text('Msimbo wa kozi'), findsOneWidget);
      expect(
        find.textContaining('Wewe ndiye mwandishi na mchapishaji'),
        findsOneWidget,
      );

      Finder field(String label) => find.ancestor(
            of: find.text(label),
            matching: find.byType(TextFormField),
          );
      final editorScroll = find.byType(Scrollable).first;
      await tester.enterText(field('Msimbo wa kozi'), 'CRS-MAH-01');
      await tester.enterText(field('Jina la kozi'), 'Kilimo cha Maharage');
      await tester.enterText(
        field('Maelezo ya kozi'),
        'Mtaala wa kilimo cha maharage.',
      );
      await tester.scrollUntilVisible(
        field('Jina la sehemu'),
        300,
        scrollable: editorScroll,
      );
      await tester.enterText(field('Jina la sehemu'), 'Maandalizi');
      await tester.enterText(field('Jina la somo'), 'Chagua shamba');
      await tester.scrollUntilVisible(
        field('Muda (dakika)'),
        300,
        scrollable: editorScroll,
      );
      await tester.enterText(field('Muda (dakika)'), '5');
      await tester.scrollUntilVisible(
        field('Maandishi ya somo'),
        300,
        scrollable: editorScroll,
      );
      await tester.enterText(
        field('Maandishi ya somo'),
        'Kagua eneo na udongo kabla ya kupanda.',
      );

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Chapisha kozi'),
        300,
        scrollable: editorScroll,
      );
      await tester.drag(editorScroll, const Offset(0, -160));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Chapisha kozi'));
      await tester.pumpAndSettle();

      expect(service.savedCourse?.id, 'CRS-MAH-01');
      expect(service.savedCourse?.lessons.single.moduleTitle, 'Maandalizi');
      expect(service.savedCourse?.lessons.single.title, 'Chagua shamba');
      expect(service.savedStatus, 'approved');
      expect(service.savedBaseUpdatedAt, isNull);
      expect(service.savedCreateOnly, isTrue);
    });
  });

  group('AccessibleTappable semantics', () {
    testWidgets('exposes one tappable button node and hides inner text',
        (tester) async {
      var taps = 0;
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTappable(
              label: 'Kadi ya kozi',
              hint: 'Fungua kozi',
              onTap: () => taps += 1,
              child: const Column(
                children: [Text('decorative-inner-label')],
              ),
            ),
          ),
        ),
      );

      // The curated label is what assistive tech announces...
      expect(find.bySemanticsLabel('Kadi ya kozi'), findsOneWidget);
      // ...and the decorative subtree is not announced separately.
      expect(find.bySemanticsLabel('decorative-inner-label'), findsNothing);
      // The inner Text still exists in the widget tree; only semantics differ.
      expect(find.text('decorative-inner-label'), findsOneWidget);

      // The tap action must survive excludeSemantics.
      tester.semantics.performAction(
        find.semantics.byLabel('Kadi ya kozi'),
        SemanticsAction.tap,
      );
      expect(taps, 1);

      handle.dispose();
    });

    testWidgets('withholds the tap action when disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTappable(
              label: 'Imezimwa',
              enabled: false,
              onTap: () {},
              child: const Text('inner'),
            ),
          ),
        ),
      );

      final data = tester
          .getSemantics(find.bySemanticsLabel('Imezimwa'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      handle.dispose();
    });
  });
}

class _DemoSnapshotCatalogService implements CatalogService {
  const _DemoSnapshotCatalogService();

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    const seed = DemoAppRepository();
    return CatalogSnapshot(
      courses: seed.courses,
      documents: seed.documents,
      problemCategories: seed.problemCategories,
      communityPosts: seed.posts,
      plans: seed.plans,
    );
  }

  @override
  Future<String> lessonVideoUrl(String lessonId) async => '';
}
