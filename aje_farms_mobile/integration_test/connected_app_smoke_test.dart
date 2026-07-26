import 'package:aje_farms_mobile/src/app.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connected Android smoke: auth and payment', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await BackendSessionStorage.writeToken(null);

    final dependencies = AppDependencies.production();
    final authRecorder = _RecordingAuthService(dependencies.authService);
    await tester.pumpWidget(AjeFarmsApp(
      dependencies: _replaceAuthService(dependencies, authRecorder),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingia / Jisajili'));
    await tester.pumpAndSettle();

    final suffix =
        DateTime.now().millisecondsSinceEpoch.toString().substring(5, 11);
    final phone = '712$suffix';
    await tester.enterText(find.byType(EditableText).first, phone);
    await tester.ensureVisible(find.text('Tuma OTP'));
    await tester.tap(find.text('Tuma OTP'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final otp = authRecorder.latestChallenge?.debugOtp;
    expect(
      otp,
      isNotNull,
      reason: 'Backend did not return a development OTP. Current texts: '
          '${_screenTexts(tester).join(' | ')}',
    );

    await tester.enterText(find.byType(EditableText).last, otp!);
    final continueButton = find.text('Endelea');
    await tester.scrollUntilVisible(
      continueButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.byType(MainShell),
      findsOneWidget,
      reason: 'Current texts: ${_screenTexts(tester).join(' | ')}',
    );

    final shellContext = tester.element(find.byType(MainShell));
    Navigator.of(shellContext).push(
      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Muda wa jaribio umeisha'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lipa TZS 10,000'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), phone);
    await tester.tap(find.text('Lipa TZS 10,000'));
    await tester.pump();

    expect(find.text('Inasubiri uthibitisho...'), findsOneWidget);
    for (var i = 0; i < 12; i += 1) {
      await tester.pump(const Duration(seconds: 1));
      if (find.text('Malipo Yamefanikiwa!').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Malipo Yamefanikiwa!'), findsOneWidget);
    expect(find.textContaining('Mwezi 1 imewashwa'), findsOneWidget);

    await tester.tap(find.text('Rudi Nyumbani'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ondoka kwenye Akaunti'), 220);
    await tester.tap(find.text('Ondoka kwenye Akaunti'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
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
