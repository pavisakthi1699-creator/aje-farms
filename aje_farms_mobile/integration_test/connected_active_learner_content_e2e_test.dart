import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _email =
    String.fromEnvironment('AJE_E2E_STANDARD_EMAIL', defaultValue: '');
const _password =
    String.fromEnvironment('AJE_E2E_STANDARD_PASSWORD', defaultValue: '');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(_supabaseUrl, isNotEmpty);
    expect(_supabasePublishableKey, isNotEmpty);
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  });

  testWidgets('active learner renders live Railway course content',
      (tester) async {
    expect(_email, isNotEmpty);
    expect(_password, isNotEmpty);

    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final dependencies = AppDependencies.production();

    await tester.pumpWidget(AjeFarmsApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), _email);
    await tester.enterText(find.byType(EditableText).at(1), _password);
    await tester.scrollUntilVisible(
      find.text('Ingia Sasa'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ingia Sasa'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(PendingAccessScreen), findsNothing);
    expect(dependencies.learningRepository.courses, hasLength(13));

    const expectedCourseTitle = 'Kilimo Cha Pasheni';
    final course = dependencies.learningRepository.courses.singleWhere(
      (candidate) => candidate.title == expectedCourseTitle,
    );
    expect(course.lessons, hasLength(6));
    expect(course.lessons.every((lesson) => lesson.description.isNotEmpty),
        isTrue);

    await tester.tap(find.text('Mafunzo'));
    await tester.pumpAndSettle();
    final courseFinder = find.text(expectedCourseTitle);
    await tester.scrollUntilVisible(
      courseFinder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(courseFinder),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(courseFinder, findsOneWidget);
    await tester.tap(courseFinder);
    await tester.pumpAndSettle();

    final firstLesson = course.lessons.first;
    final lessonFinder = find.text(firstLesson.title);
    await Scrollable.ensureVisible(
      tester.element(lessonFinder),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(lessonFinder);
    await tester.pumpAndSettle();
    expect(find.text(firstLesson.description), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
