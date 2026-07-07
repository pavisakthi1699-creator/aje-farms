import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the demo app through release-screenshot checkpoints and saves PNGs
/// via [IntegrationTestWidgetsFlutterBinding.takeScreenshot].
///
/// Run on a connected Android emulator/device:
/// `flutter test integration_test/release_screenshot_tour_test.dart`
///
/// Output (host): `build/integration_test_screenshots/release_screenshot_tour_test/`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> snap(String name) async {
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(name);
  }

  void useViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> tapNavTab(WidgetTester tester, IconData icon) async {
    final bar = find.byType(NavigationBar);
    if (bar.evaluate().isNotEmpty) {
      await tester.tap(
        find.descendant(of: bar, matching: find.byIcon(icon)),
      );
    } else {
      await tester.tap(
        find.descendant(of: find.byType(NavigationRail), matching: find.byIcon(icon)),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> startDemoShell(WidgetTester tester) async {
    await tester.tap(find.text('Anza Sasa'));
    await tester.pumpAndSettle();
  }

  testWidgets('release screenshot tour (demo, light)', (tester) async {
    useViewport(tester, const Size(390, 844));

    await tester.pumpWidget(AjeFarmsApp(dependencies: AppDependencies.demo()));
    await tester.pumpAndSettle();

    await snap('01-onboarding-phone-light');
    await tester.tap(find.text('Ingia / Jisajili'));
    await tester.pumpAndSettle();
    await snap('02-auth-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await startDemoShell(tester);
    await snap('03-dashboard-phone-light');

    await tester.tap(find.byTooltip('Arifa'));
    await tester.pumpAndSettle();
    await snap('04-notifications-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eleza tatizo'));
    await tester.pumpAndSettle();
    await snap('05-problem-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapNavTab(tester, Icons.menu_book_outlined);
    await snap('06-courses-phone-light');

    final dashboardCourse =
        find.byKey(const ValueKey('dashboard-course-tap-pasheni'));
    await tapNavTab(tester, Icons.home_outlined);
    await tester.ensureVisible(dashboardCourse);
    await tester.tap(dashboardCourse);
    await tester.pumpAndSettle();
    await snap('07-course-detail-phone-light');

    await tester.tap(find.text('Maandalizi ya shamba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fungua Somo la Mfano'));
    await tester.pumpAndSettle();
    await snap('08-lesson-sheet-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Jaribio la maarifa'), 240);
    await tester.tap(find.text('Jaribio la maarifa'));
    await tester.pumpAndSettle();
    await snap('09-paywall-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapNavTab(tester, Icons.groups_outlined);
    await snap('10-community-phone-light');

    final postCard =
        find.byKey(const ValueKey('community-post-seed-pasheni-disease'));
    await tester.ensureVisible(postCard);
    await tester.tap(postCard);
    await tester.pumpAndSettle();
    await snap('11-post-detail-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapNavTab(tester, Icons.smart_toy_outlined);
    await snap('12-ai-chat-phone-light');

    await tapNavTab(tester, Icons.person_outline);
    await snap('13-profile-phone-light');

    await tester.tap(find.text('Mipangilio'));
    await tester.pumpAndSettle();
    await snap('14-settings-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Msaada / WhatsApp'), 240);
    await tester.tap(find.text('Msaada / WhatsApp'));
    await tester.pumpAndSettle();
    await snap('15-whatsapp-phone-light');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Dark-mode smoke (dashboard + settings segmented control).
    await tapNavTab(tester, Icons.person_outline);
    await tester.tap(find.text('Mipangilio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giza'));
    await tester.pumpAndSettle();
    await snap('16-settings-phone-dark');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapNavTab(tester, Icons.home_outlined);
    await tester.pumpAndSettle();
    await snap('17-dashboard-phone-dark');
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('release screenshot tour (demo, tablet wide)', (tester) async {
    useViewport(tester, const Size(900, 1200));

    await tester.pumpWidget(AjeFarmsApp(dependencies: AppDependencies.demo()));
    await tester.pumpAndSettle();

    await snap('21-onboarding-tablet-light');
    await startDemoShell(tester);
    await snap('22-dashboard-tablet-light');

    await tapNavTab(tester, Icons.menu_book_outlined);
    await snap('23-courses-tablet-light');

    await tapNavTab(tester, Icons.groups_outlined);
    await snap('24-community-tablet-light');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
