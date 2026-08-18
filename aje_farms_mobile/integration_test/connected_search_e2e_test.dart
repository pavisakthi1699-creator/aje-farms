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

  testWidgets('active learner searches live content and opens a result',
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
    await _pumpUntil(
        tester, () => find.byType(MainShell).evaluate().isNotEmpty);

    expect(find.byType(MainShell), findsOneWidget);
    expect(
        tester.element(find.byType(MainShell)).session.hasActiveAccess, isTrue);

    await tester.tap(find.byTooltip('Tafuta'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Zote'))
          .selected,
      isTrue,
    );

    const courseTitle = 'Kilimo Cha Pasheni';
    await tester.enterText(find.byType(EditableText).first, courseTitle);
    await tester.pump(const Duration(milliseconds: 350));
    final courseResult = find.descendant(
      of: find.byType(ListTile),
      matching: find.text(courseTitle),
    );
    await _pumpUntil(tester, () => courseResult.evaluate().isNotEmpty);

    expect(find.textContaining('matokeo yamepatikana.'), findsOneWidget);
    expect(courseResult, findsOneWidget);
    expect(
      find.text(
          'Matokeo yanatoka kwenye maudhui yaliyohifadhiwa. Huenda si kamili.'),
      findsNothing,
      reason: 'The connected search unexpectedly fell back to offline results.',
    );

    await tester.tap(courseResult);
    await tester.pumpAndSettle();
    expect(find.byType(CourseDetailScreen), findsOneWidget);
    expect(find.text(courseTitle), findsWidgets);

    Navigator.of(tester.element(find.byType(CourseDetailScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(SearchScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mafunzo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tafuta kozi au somo'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Mafunzo'))
          .selected,
      isTrue,
      reason: 'The courses entry point must preserve the learning scope.',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var attempt = 0; attempt < 30 && !condition(); attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}
