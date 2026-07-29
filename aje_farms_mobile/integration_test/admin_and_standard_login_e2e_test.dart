import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Requires two pre-seeded, email-confirmed Supabase Auth accounts on the
// target project (set via --dart-define=AJE_API_BASE_URL=... against a
// running backend pointed at that project):
//   - AJE_E2E_STANDARD_EMAIL / AJE_E2E_STANDARD_PASSWORD: an ordinary learner
//   - AJE_E2E_ADMIN_EMAIL / AJE_E2E_ADMIN_PASSWORD: an account whose email is
//     in AJE_ADMIN_EMAILS on the backend
// Unlike the old OTP flow, sign-in goes straight to Supabase Auth — there is
// no debug bypass reachable from the Flutter client, so these accounts must
// already exist and be confirmed before this test runs.
const _standardEmail =
    String.fromEnvironment('AJE_E2E_STANDARD_EMAIL', defaultValue: '');
const _standardPassword =
    String.fromEnvironment('AJE_E2E_STANDARD_PASSWORD', defaultValue: '');
const _adminEmail =
    String.fromEnvironment('AJE_E2E_ADMIN_EMAIL', defaultValue: '');
const _adminPassword =
    String.fromEnvironment('AJE_E2E_ADMIN_PASSWORD', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real auth: standard user blocked, admin user allowed dashboard',
    (tester) async {
      expect(
        _standardEmail.isNotEmpty && _adminEmail.isNotEmpty,
        isTrue,
        reason: 'Pass AJE_E2E_STANDARD_EMAIL/PASSWORD and '
            'AJE_E2E_ADMIN_EMAIL/PASSWORD via --dart-define to run this test.',
      );

      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();

      final dependencies = AppDependencies.production();
      await tester.pumpWidget(AjeFarmsApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      await _login(tester, _standardEmail, _standardPassword);
      expect(find.byType(MainShell), findsOneWidget);

      await _openProfile(tester);
      expect(find.text('Dashibodi ya Admin'), findsNothing);
      await _logout(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await _login(tester, _adminEmail, _adminPassword);
      expect(find.byType(MainShell), findsOneWidget);

      await _openProfile(tester);
      final adminDashboard = find.text('Dashibodi ya Admin');
      expect(adminDashboard, findsOneWidget);

      final shellContext = tester.element(find.byType(MainShell));
      Navigator.of(shellContext).push(
        MaterialPageRoute<void>(builder: (_) => const AdminDashboardScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashibodi ya Admin'), findsOneWidget);
      expect(find.text('Maandishi'), findsOneWidget);
      expect(find.text('Usimamizi'), findsOneWidget);
      expect(find.text('Watumiaji'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _login(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.tap(find.text('Ingia / Jisajili'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(EditableText).at(0), email);
  await tester.enterText(find.byType(EditableText).at(1), password);
  await tester.scrollUntilVisible(
    find.text('Ingia'),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Ingia'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _openProfile(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline));
  await tester.pumpAndSettle();
}

Future<void> _logout(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Ondoka kwenye Akaunti'), 220);
  await tester.tap(find.text('Ondoka kwenye Akaunti'));
  await tester.pumpAndSettle();
}
