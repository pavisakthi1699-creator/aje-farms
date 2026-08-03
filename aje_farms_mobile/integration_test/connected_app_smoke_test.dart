import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Requires a pre-seeded, email-confirmed Supabase Auth account on the target
// project — see admin_and_standard_login_e2e_test.dart for why there's no
// debug bypass to fall back on. This account should be `pending_activation`
// (never had a payment approved) so the awaiting-activation screen is what's
// under test, matching what a freshly signed-up learner actually sees.
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

  testWidgets('connected Android smoke: sign in and awaiting activation',
      (tester) async {
    expect(
      _email.isNotEmpty,
      isTrue,
      reason: 'Pass AJE_E2E_STANDARD_EMAIL/PASSWORD via --dart-define to '
          'run this test.',
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    final dependencies = AppDependencies.production();
    await tester.pumpWidget(AjeFarmsApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    await tester.enterText(find.byType(EditableText).at(0), _email);
    await tester.enterText(find.byType(EditableText).at(1), _password);
    await tester.scrollUntilVisible(
      find.text('Ingia Sasa'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ingia Sasa'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(PendingAccessScreen), findsOneWidget,
        reason: 'Current texts: ${_screenTexts(tester).join(' | ')}');
    expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
    await tester.tap(find.text('Onyesha Hali Upya'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.scrollUntilVisible(find.text('Ondoka kwenye Akaunti'), 220);
    await tester.tap(find.text('Ondoka kwenye Akaunti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ondoka'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

List<String> _screenTexts(WidgetTester tester) {
  return find
      .byType(Text)
      .evaluate()
      .map((element) => tester.widget<Text>(find.byWidget(element.widget)).data)
      .whereType<String>()
      .toList();
}
