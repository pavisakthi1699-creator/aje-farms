import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('published poultry course completes end to end', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final session = AppSessionController(preferences: preferences);
    await session.startAsGuest();

    final dependencies = AppDependencies.production();
    await dependencies.refreshCatalog();
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: dependencies,
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mafunzo'));
    await tester.pumpAndSettle();

    const courseTitle = 'Usalama wa Banda na Ufuatiliaji wa Afya ya Kuku';
    final courseFinder = find.text(courseTitle);
    await tester.scrollUntilVisible(
      courseFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(courseFinder, findsOneWidget);
    expect(find.text('Kozi ya maandishi'), findsWidgets);
    expect(find.text('0/3 masomo'), findsOneWidget);

    final course = dependencies.learningRepository.courses.singleWhere(
      (item) => item.id == 'CRS-KUK-02',
    );
    final catalogContext = tester.element(courseFinder);
    Navigator.of(catalogContext).push(
      MaterialPageRoute<void>(
        builder: (_) => CourseDetailScreen(course: course),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(courseTitle), findsWidgets);
    expect(
      find.textContaining('Haitoi utambuzi wa ugonjwa'),
      findsOneWidget,
    );

    const lessons = <({String title, String expectedBody})>[
      (
        title: 'Tenga Kuku Wapya na Dhibiti Viatu',
        expectedBody: 'Watenganishe na kuku waliopo kwa angalau wiki mbili',
      ),
      (
        title: 'Ratiba ya Usafi wa Banda na Vifaa',
        expectedBody: 'Ondoa kinyesi na takataka',
      ),
      (
        title: 'Fuatilia Afya na Weka Kumbukumbu',
        expectedBody: 'Weka kumbukumbu za chanjo',
      ),
    ];

    for (final lesson in lessons) {
      final lessonFinder = find.text(lesson.title);
      await Scrollable.ensureVisible(
        tester.element(lessonFinder),
        alignment: 0.5,
      );
      await tester.pump();
      await tester.tap(lessonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining(lesson.expectedBody), findsOneWidget);
      expect(
        find.text(
          'Chanzo: MAGONJWA YA KUKU TIBA ZAKE ZA ASILI',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('aspirin'), findsNothing);
      expect(find.textContaining('ibuprofen'), findsNothing);
      expect(find.textContaining('paracetamol'), findsNothing);

      await tester.tap(find.text('Kamilisha Somo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.text('3/3'), findsOneWidget);
    expect(
      find.text(
        'Umemaliza masomo yote. Unaweza kurudia masomo au kumuuliza '
        'Mwalimu AI swali la kozi.',
      ),
      findsOneWidget,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
