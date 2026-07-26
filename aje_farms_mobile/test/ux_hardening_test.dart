import 'package:aje_farms_mobile/src/app.dart';
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
                'Somo halijaunganishwa na hati chanzo.',
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

class _SourceReviewAdminService extends _RecordingCourseAdminService {
  String? approvedLessonId;
  String? approvedSegmentId;
  String? evidenceNote;
  String? groundingFact;

  @override
  Future<List<AdminSourceSegment>> searchSourceSegments({
    String search = '',
  }) async {
    return const [
      AdminSourceSegment(
        id: 'segment-1',
        documentId: 'document-1',
        documentTitle: 'Kitabu cha Kilimo cha Nyanya',
        sectionTitle: 'Maandalizi ya kitalu',
        locationLabel: 'Kurasa 10-12',
        contentPreview: 'Chagua eneo safi na lenye mifereji mizuri.',
      ),
    ];
  }

  @override
  Future<AdminLessonSourceReviewResult> approveLessonSource({
    required String lessonId,
    required String sourceSegmentId,
    required String evidenceNote,
    required String groundingFact,
  }) async {
    approvedLessonId = lessonId;
    approvedSegmentId = sourceSegmentId;
    this.evidenceNote = evidenceNote;
    this.groundingFact = groundingFact;
    return AdminLessonSourceReviewResult(
      courseUpdatedAt: DateTime.utc(2026, 7, 26, 12),
      contentReady: true,
    );
  }
}

class _ApprovedSourceReviewAdminService extends _SourceReviewAdminService {
  @override
  Future<List<AdminContentCourseRecord>> listContentCourses() async {
    return [
      AdminContentCourseRecord(
        id: 'course-1',
        status: 'approved',
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
              isLearnerVisible: true,
            ),
          ],
        ),
      ),
    ];
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

  group('auth inline validation', () {
    testWidgets('rejects a short phone number inline rather than via snack bar',
        (tester) async {
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, '12');
      await tester.tap(find.text('Tuma OTP'));
      await tester.pumpAndSettle();

      expect(
        find.text('Namba ya simu inahitaji tarakimu 9 au zaidi.'),
        findsOneWidget,
      );
      // No OTP field should have appeared, i.e. the request was not sent.
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('rejects non-numeric input', (tester) async {
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, '7123abcde');
      await tester.tap(find.text('Tuma OTP'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tumia tarakimu tu, bila nafasi au alama.'),
        findsOneWidget,
      );
    });

    testWidgets('clears the inline error once the user edits the field',
        (tester) async {
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, '12');
      await tester.tap(find.text('Tuma OTP'));
      await tester.pumpAndSettle();
      expect(
        find.text('Namba ya simu inahitaji tarakimu 9 au zaidi.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(EditableText).first, '712345678');
      // InputDecorator fades the error out, so settle past the animation.
      await tester.pumpAndSettle();

      expect(
        find.text('Namba ya simu inahitaji tarakimu 9 au zaidi.'),
        findsNothing,
      );
    });

    testWidgets('offers resend on cooldown after a successful OTP request',
        (tester) async {
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, '712345678');
      await tester.tap(find.text('Tuma OTP'));
      await tester.pumpAndSettle();

      // Cooldown matches the server-side 60s per-number rate limit.
      expect(find.text('Tuma tena baada ya sekunde 60'), findsOneWidget);
      final resend = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Tuma tena baada ya sekunde 60'),
          matching: find.byType(TextButton),
        ),
      );
      expect(resend.onPressed, isNull);
    });

    testWidgets('phone and OTP fields declare autofill hints', (tester) async {
      await tester.pumpWidget(wrapAuth());

      await tester.enterText(find.byType(EditableText).first, '712345678');
      await tester.tap(find.text('Tuma OTP'));
      await tester.pumpAndSettle();

      final hints = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.autofillHints)
          .whereType<Iterable<String>>()
          .expand((hint) => hint)
          .toList();

      expect(hints, contains(AutofillHints.telephoneNumber));
      // Lets the platform auto-populate the code straight from the SMS.
      expect(hints, contains(AutofillHints.oneTimeCode));
    });
  });

  group('destructive actions require confirmation', () {
    Future<void> openProfile(
        WidgetTester tester, AppSessionController session) async {
      await tester.pumpWidget(
        AjeFarmsApp(
          dependencies: AppDependencies.demo(),
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
      await session.signInWithPhone('+255700111222', role: 'learner');
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
      await session.signInWithPhone('+255700111222', role: 'learner');
      await openProfile(tester, session);

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
    });
  });

  group('admin dashboard', () {
    /// Opens the admin dashboard with [adminService] backing it.
    Future<void> openAdminDashboard(
      WidgetTester tester, {
      required AdminService adminService,
    }) async {
      final session = AppSessionController();
      await session.signInWithPhone('+255799000111', role: 'admin');

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
      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi'));
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
        find.textContaining('huhifadhiwa kama rasimu'),
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
        find.text('Hifadhi mtaala mzima'),
        400,
        scrollable: editorScroll,
      );
      await tester.tap(find.text('Hifadhi mtaala mzima'));
      await tester.pumpAndSettle();

      expect(service.savedCourse?.id, 'CRS-MAH-01');
      expect(service.savedCourse?.lessons.single.moduleTitle, 'Maandalizi');
      expect(service.savedCourse?.lessons.single.title, 'Chagua shamba');
      expect(service.savedStatus, 'draft');
      expect(service.savedBaseUpdatedAt, isNull);
      expect(service.savedCreateOnly, isTrue);
    });

    testWidgets('blocked lessons expose source-link and approval controls',
        (tester) async {
      final service = _SourceReviewAdminService();
      await openAdminDashboard(tester, adminService: service);

      await tester.tap(find.text('Kagua chanzo cha masomo 1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Unganisha chanzo na idhinisha'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unganisha chanzo na idhinisha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unganisha chanzo na idhinisha'));
      await tester.pumpAndSettle();

      expect(find.text('Kitabu cha Kilimo cha Nyanya'), findsOneWidget);
      await tester.tap(find.text('Kitabu cha Kilimo cha Nyanya'));
      await tester.pumpAndSettle();
      Finder reviewField(String label) => find.ancestor(
            of: find.text(label),
            matching: find.byType(TextField),
          );
      await tester.enterText(
        reviewField('Maelezo ya ushahidi'),
        'Sehemu inaunga mkono somo.',
      );
      await tester.enterText(
        reviewField('Ukweli wa msingi uliothibitishwa'),
        'Kitalu kinahitaji eneo safi lenye mifereji mizuri.',
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Unganisha na idhinisha'),
      );
      await tester.pumpAndSettle();

      expect(service.approvedLessonId, 'lesson-1');
      expect(service.approvedSegmentId, 'segment-1');
      expect(service.evidenceNote, 'Sehemu inaunga mkono somo.');
      expect(
        service.groundingFact,
        'Kitalu kinahitaji eneo safi lenye mifereji mizuri.',
      );
      await tester.tap(find.text('Hifadhi'));
      await tester.pumpAndSettle();
      expect(
        service.savedBaseUpdatedAt,
        DateTime.utc(2026, 7, 26, 12),
      );
    });

    testWidgets('approved lessons still expose a source review action',
        (tester) async {
      await openAdminDashboard(
        tester,
        adminService: _ApprovedSourceReviewAdminService(),
      );

      await tester.tap(find.text('Hariri maudhui na mtaala'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Kagua au badilisha chanzo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Kagua au badilisha chanzo'), findsOneWidget);
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
