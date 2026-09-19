import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all reviewed text courses are wired and complete end to end',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final session = AppSessionController(preferences: preferences);
    await session.startAsGuest();

    final dependencies = AppDependencies.production();
    await dependencies.refreshCatalog();
    for (var attempt = 0; attempt < 20; attempt += 1) {
      final cache = dependencies.cachedRepository;
      if (cache == null ||
          (!cache.isInitialLoadPending && !cache.isRefreshing)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (dependencies.cachedRepository?.lastRefreshFailed ?? false) {
      await dependencies.refreshCatalog();
    }

    const expectedCourses = <String, String>{
      'CRS-001': 'Kuanzisha Bustani Salama ya Familia',
      'CRS-ALZ-01': 'Misingi ya Shamba na Uvunaji wa Alizeti',
      'CRS-CHK-01': 'Misingi ya Shamba na Ubora wa Chikichi',
      'CRS-KUK-01': 'Usalama wa Lishe na Uhifadhi wa Chakula cha Kuku',
      'CRS-MGB-01': 'Aina, Usafi na Uvunaji wa Ndizi',
      'CRS-MHG-01': 'Maandalizi na Utunzaji Baada ya Mavuno ya Muhogo',
      'CRS-MPU-01': 'Maandalizi, Maji na Soko la Mpunga',
      'CRS-NAN-01': 'Misingi ya Aina, Eneo na Thamani ya Nanasi',
      'CRS-PSH-01': 'Misingi ya Kuanzisha Shamba la Pasheni',
    };
    final reviewedCourses = expectedCourses.keys
        .map(
          (id) => dependencies.learningRepository.courses.singleWhere(
            (course) => course.id == id,
          ),
        )
        .toList();

    for (final course in reviewedCourses) {
      expect(course.title, expectedCourses[course.id]);
      expect(course.badge, 'Kozi ya maandishi');
      expect(course.lessons, hasLength(3));
      expect(course.outcomes, hasLength(1));
      for (final lesson in course.lessons) {
        expect(lesson.type, LessonType.reading);
        expect(lesson.description.trim(), isNotEmpty);
        expect(lesson.sourceTitle?.trim(), isNotEmpty);
        expect(
          lesson.description,
          isNot(matches(RegExp(
            r'\b\d+(?:[.,]\d+)?\s*%|amoxicillin|oxytetracycline|tylosin|sulphadimidine',
            caseSensitive: false,
          ))),
        );
      }
    }

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: dependencies,
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);

    await tester.tap(find.text('Mafunzo'));
    await tester.pumpAndSettle();
    for (final title in expectedCourses.values) {
      final courseFinder = find.text(title);
      await tester.scrollUntilVisible(
        courseFinder,
        320,
        scrollable: find.byType(Scrollable).first,
      );
      expect(courseFinder, findsOneWidget);
    }

    for (final course in reviewedCourses) {
      final shellContext = tester.element(find.byType(MainShell));
      Navigator.of(shellContext).push(
        MaterialPageRoute<void>(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(course.title), findsWidgets);
      expect(find.text('0/3'), findsOneWidget);

      for (final lesson in course.lessons) {
        final lessonFinder = find.text(lesson.title);
        await Scrollable.ensureVisible(
          tester.element(lessonFinder),
          alignment: 0.5,
        );
        await tester.pump();
        await tester.tap(lessonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(lesson.description), findsOneWidget);
        expect(find.text('Chanzo: ${lesson.sourceTitle}'), findsOneWidget);
        await tester.tap(find.text('Kamilisha Somo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text('3/3'), findsOneWidget);
      expect(
        find.textContaining('Umemaliza masomo yote'),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.text(course.title).first)).pop();
      await tester.pumpAndSettle();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
