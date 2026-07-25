import 'package:aje_farms_mobile/src/app.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real auth: standard user blocked, admin user allowed dashboard',
    (tester) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      await BackendSessionStorage.writeToken(null);

      final dependencies = AppDependencies.production();
      final authRecorder = _RecordingAuthService(dependencies.authService);
      await tester.pumpWidget(AjeFarmsApp(
        dependencies: _replaceAuthService(dependencies, authRecorder),
      ));
      await tester.pumpAndSettle();

      final suffix =
          DateTime.now().millisecondsSinceEpoch.toString().substring(5, 11);
      final standardPhone = '712$suffix';
      await _loginWithOtp(tester, authRecorder, standardPhone);
      expect(find.byType(MainShell), findsOneWidget);

      await _openProfile(tester);
      expect(find.text('Dashibodi ya Admin'), findsNothing);
      await _logout(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await _loginWithOtp(tester, authRecorder, '799000111');
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

Future<void> _loginWithOtp(
  WidgetTester tester,
  _RecordingAuthService authRecorder,
  String localPhoneDigits,
) async {
  await tester.tap(find.text('Ingia / Jisajili'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(EditableText).first, localPhoneDigits);
  await tester.ensureVisible(find.text('Tuma OTP'));
  await tester.tap(find.text('Tuma OTP'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final otp = authRecorder.latestChallenge?.debugOtp;
  expect(
    otp,
    isNotNull,
    reason: 'Backend did not return development OTP.',
  );

  await tester.enterText(find.byType(EditableText).last, otp!);
  await tester.scrollUntilVisible(
    find.text('Endelea'),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Endelea'));
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

AppDependencies _replaceAuthService(
  AppDependencies dependencies,
  AuthService authService,
) {
  return AppDependencies(
    learningRepository: dependencies.learningRepository,
    communityRepository: dependencies.communityRepository,
    subscriptionRepository: dependencies.subscriptionRepository,
    mwalimuAiService: dependencies.mwalimuAiService,
    authService: authService,
    catalogService: dependencies.catalogService,
    adminService: dependencies.adminService,
    communityService: dependencies.communityService,
    learningProgressService: dependencies.learningProgressService,
    notificationService: dependencies.notificationService,
    paymentService: dependencies.paymentService,
    refreshCatalog: dependencies.refreshCatalog,
    refreshListenable: dependencies.refreshListenable,
  );
}

class _RecordingAuthService implements AuthService {
  _RecordingAuthService(this._delegate);

  final AuthService _delegate;
  OtpChallenge? latestChallenge;

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    latestChallenge = await _delegate.requestOtp(phoneNumber);
    return latestChallenge!;
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  }) {
    return _delegate.verifyOtp(
      phoneNumber: phoneNumber,
      otp: otp,
      challengeId: challengeId,
    );
  }

  @override
  Future<AuthSession> getSession(String phoneNumber) {
    return _delegate.getSession(phoneNumber);
  }

  @override
  Future<AuthSession> cancelSubscription(String phoneNumber) {
    return _delegate.cancelSubscription(phoneNumber);
  }

  @override
  Future<AuthSession> updateProfile({
    required String phoneNumber,
    String? displayName,
    String? preferredLocation,
  }) {
    return _delegate.updateProfile(
      phoneNumber: phoneNumber,
      displayName: displayName,
      preferredLocation: preferredLocation,
    );
  }

  @override
  Future<AdminAccessDiagnostics> getAdminAccessDiagnostics() {
    return _delegate.getAdminAccessDiagnostics();
  }
}
