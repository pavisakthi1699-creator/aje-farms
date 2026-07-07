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

    await tester.pumpWidget(const AjeFarmsApp());
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

    final debugOtpFinder = find.textContaining('OTP ya majaribio:');
    expect(debugOtpFinder, findsOneWidget);
    final debugOtpText = tester.widget<Text>(debugOtpFinder).data!;
    final otp = RegExp(r'\d{6}').firstMatch(debugOtpText)!.group(0)!;

    await tester.enterText(find.byType(EditableText).last, otp);
    await tester.ensureVisible(find.text('Endelea'));
    await tester.tap(find.text('Endelea'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Karibu, Mkulima'), findsOneWidget);

    final shellContext = tester.element(find.byType(MainShell));
    Navigator.of(shellContext).push(
      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Muda wa jaribio umeisha'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lipa TZS 10,000'), 240);
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

    expect(find.text('Anza Sasa'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
