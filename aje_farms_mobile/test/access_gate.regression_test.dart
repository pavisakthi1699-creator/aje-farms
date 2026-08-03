import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aje_farms_mobile/src/app.dart';

import 'support/stub_auth_service.dart';

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<AppSessionController> signedInSession({String? accountStatus}) async {
    final session = AppSessionController();
    await session.signInWithEmail('mkulima@aje.test', role: 'learner');
    if (accountStatus != null) {
      await session.syncAccountStatusFromAuthSession(
        AuthSession(email: 'mkulima@aje.test', accountStatus: accountStatus),
      );
    }
    return session;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
      'a registered but unapproved learner is held at the Swahili pending '
      'screen instead of the learner shell', (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'pending_activation');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('pending_activation'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hali ya Akaunti'), findsOneWidget);
    expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);
    expect(
      find.text(
        'Umesajiliwa. Timu ya AJE Farms itathibitisha akaunti yako '
        'ili kufungua mafunzo.',
      ),
      findsOneWidget,
    );

    // The shell itself must not be behind the wall: no tabs, no dashboard.
    expect(find.textContaining('Karibu'), findsNothing);
    expect(find.text('Nyumbani'), findsNothing);
    expect(find.text('Mafunzo'), findsNothing);
    expect(find.text('Uliza AI'), findsNothing);
  });

  testWidgets('a suspended account is told so, in Swahili',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'suspended');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('suspended'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Akaunti yako imesitishwa'), findsOneWidget);
    expect(find.textContaining('Karibu'), findsNothing);
  });

  testWidgets('an approved learner still reaches the shell',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'active');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('active'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Karibu'), findsOneWidget);
    expect(find.text('Hali ya Akaunti'), findsNothing);
  });

  testWidgets('approval mid-session opens the app without a restart',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = await signedInSession(accountStatus: 'pending_activation');
    final authService = StubAuthService('pending_activation');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies:
            AppDependencies.demo().copyWith(authService: authService),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);

    authService.accountStatus = 'active';
    await tester.ensureVisible(find.text('Onyesha Hali Upya'));
    await tester.tap(find.text('Onyesha Hali Upya'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Karibu'), findsOneWidget);
  });
}
