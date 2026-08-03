import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      expect(
        find.byType(PendingAccessScreen),
        findsOneWidget,
        reason: 'Learner login screen: ${_screenTexts().join(' | ')}',
      );
      expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
      await _logout(tester);
      expect(find.byType(AuthScreen), findsOneWidget);

      await _login(tester, _adminEmail, _adminPassword);
      expect(
        find.byType(MainShell),
        findsOneWidget,
        reason: 'Admin login screen: ${_screenTexts().join(' | ')}',
      );
      final adminShellContext = tester.element(find.byType(MainShell));
      expect(
        adminShellContext.session.isAdmin,
        isTrue,
        reason: 'Admin role was not synchronized into the Flutter session.',
      );

      await _openProfile(tester);
      await tester.scrollUntilVisible(
        find.text('Dashibodi ya Admin'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
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

      await tester.tap(find.text('Malipo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Tafuta mkulima kwa barua pepe'),
        _standardEmail,
      );
      await tester.tap(find.byTooltip('Tafuta'));
      await tester.pumpAndSettle();
      final learnerResult = find.ancestor(
        of: find.text(_standardEmail),
        matching: find.byType(ListTile),
      );
      expect(learnerResult, findsOneWidget);
      await tester.ensureVisible(learnerResult);
      await tester.tap(learnerResult);
      await tester.pumpAndSettle();
      expect(find.text('Badilisha'), findsOneWidget);
      expect(
        find.byType(ListView),
        findsWidgets,
        reason: 'Payments form did not render: ${_screenTexts().join(' | ')}',
      );
      await _dragListUntilText(tester, 'Rekodi Malipo');
      await tester.tap(find.text('Rekodi Malipo'));
      await tester.pumpAndSettle();
      expect(
        find.text('Malipo yamerekodiwa. Yanasubiri idhini.'),
        findsOneWidget,
      );
      await _dragListUntilText(tester, 'Idhinisha');
      await tester.tap(find.text('Idhinisha').last);
      await tester.pumpAndSettle();
      final approvalConfirmation = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Idhinisha'),
      );
      expect(approvalConfirmation, findsOneWidget);
      await tester.tap(approvalConfirmation);
      for (var attempt = 0;
          attempt < 20 &&
              find.text('Hakuna malipo yanayosubiri').evaluate().isEmpty;
          attempt += 1) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(
        find.text('Hakuna malipo yanayosubiri'),
        findsOneWidget,
        reason: 'Approval result: ${_screenTexts().join(' | ')}',
      );

      Navigator.of(tester.element(find.byType(AdminDashboardScreen))).pop();
      await tester.pumpAndSettle();
      await _resetSessionForNextLogin(tester);
      await _login(tester, _standardEmail, _standardPassword);
      final shellContextAfterApproval = tester.element(find.byType(MainShell));
      expect(
        shellContextAfterApproval.session.state.accountStatus,
        'active',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _login(
  WidgetTester tester,
  String email,
  String password,
) async {
  expect(find.byType(AuthScreen), findsOneWidget);
  await tester.enterText(find.byType(EditableText).at(0), email);
  await tester.enterText(find.byType(EditableText).at(1), password);
  await tester.scrollUntilVisible(
    find.text('Ingia Sasa'),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Ingia Sasa'));
  for (var attempt = 0;
      attempt < 20 &&
          find.byType(MainShell).evaluate().isEmpty &&
          find.byType(PendingAccessScreen).evaluate().isEmpty;
      attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

Future<void> _openProfile(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline));
  await tester.pumpAndSettle();
  expect(
    find.byType(ProfileScreen),
    findsOneWidget,
    reason: 'Profile navigation failed: ${_screenTexts().join(' | ')}',
  );
}

Future<void> _logout(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Ondoka kwenye Akaunti'), 220);
  await tester.tap(find.text('Ondoka kwenye Akaunti'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ondoka'));
  for (var attempt = 0;
      attempt < 10 && find.byType(AuthScreen).evaluate().isEmpty;
      attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

Future<void> _resetSessionForNextLogin(WidgetTester tester) async {
  final context = tester.element(find.byType(ProfileScreen));
  ScaffoldMessenger.of(context).clearSnackBars();
  await context.dependencies.authService.signOut();
  await context.session.signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    (_) => false,
  );
  await tester.pumpAndSettle();
}

List<String> _screenTexts() {
  return find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
}

Future<void> _dragListUntilText(WidgetTester tester, String text) async {
  for (var attempt = 0;
      attempt < 12 && find.text(text).evaluate().isEmpty;
      attempt += 1) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
  }
  expect(
    find.text(text),
    findsWidgets,
    reason: 'Could not find "$text": ${_screenTexts().join(' | ')}',
  );
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
}
