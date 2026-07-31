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
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  /// Never use pumpAndSettle on device — shimmer skeletons loop forever.
  Future<void> settle(
    WidgetTester tester, {
    Duration wait = const Duration(milliseconds: 700),
  }) async {
    await tester.pump();
    await tester.pump(wait);
  }

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = true;
    await GoogleFonts.pendingFonts([
      GoogleFonts.atkinsonHyperlegible(),
      GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w600),
      GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w700),
      GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold),
    ]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> prepareScreenshots(WidgetTester tester) async {
    await settle(tester, wait: const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
  }

  Future<void> snap(String name) async {
    await binding.takeScreenshot(name);
  }

  Future<void> scrollToVisible(
    WidgetTester tester,
    Finder finder, {
    double delta = 240,
    int maxScrolls = 12,
  }) async {
    for (var i = 0; i < maxScrolls; i++) {
      if (tester.any(finder)) {
        await tester.ensureVisible(finder);
        return;
      }
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isEmpty) {
        break;
      }
      await tester.drag(scrollable, Offset(0, -delta));
      await settle(tester);
    }
    await tester.ensureVisible(finder);
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
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byIcon(icon),
        ),
      );
    }
    await settle(tester);
  }

  Future<void> startDemoShell(WidgetTester tester) async {
    final start = find.text('Ingia / Jisajili');
    await scrollToVisible(tester, start);
    await tester.tap(start);
    await settle(tester);
    await tester.enterText(find.byType(EditableText).at(0), 'mkulima@demo.aje');
    await tester.enterText(find.byType(EditableText).at(1), 'nenosiri');
    await scrollToVisible(tester, find.text('Ingia Sasa'));
    await tester.tap(find.text('Ingia Sasa'));
    await settle(tester);
  }

  Future<void> launchDemo(
    WidgetTester tester, {
    required Size viewport,
  }) async {
    useViewport(tester, viewport);
    await tester.pumpWidget(AjeFarmsApp(dependencies: AppDependencies.demo()));
    await prepareScreenshots(tester);
  }

  testWidgets('release screenshots phone — shell & learning', (tester) async {
    await launchDemo(tester, viewport: const Size(390, 844));

    await snap('01-onboarding-phone-light');
    await tester.tap(find.text('Ingia / Jisajili'));
    await settle(tester);
    await snap('02-auth-phone-light');
    await tester.pageBack();
    await settle(tester);

    await startDemoShell(tester);
    await snap('03-dashboard-phone-light');

    await tester.tap(find.byTooltip('Arifa'));
    await settle(tester);
    await snap('04-notifications-phone-light');
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('Eleza tatizo'));
    await settle(tester);
    await snap('05-problem-phone-light');
    await tester.pageBack();
    await settle(tester);

    await tapNavTab(tester, Icons.menu_book_outlined);
    await snap('06-courses-phone-light');

    final dashboardCourse =
        find.byKey(const ValueKey('dashboard-course-tap-pasheni'));
    await tapNavTab(tester, Icons.home_outlined);
    await tester.ensureVisible(dashboardCourse);
    await tester.tap(dashboardCourse);
    await settle(tester);
    await snap('07-course-detail-phone-light');

    await scrollToVisible(tester, find.text('Maandalizi ya shamba'));
    await tester.tap(find.text('Maandalizi ya shamba'));
    await settle(tester);
    await tester.tap(find.text('Fungua Somo la Mfano'));
    await settle(tester);
    await snap('08-lesson-sheet-phone-light');
    await tester.pageBack();
    await settle(tester);

    await scrollToVisible(tester, find.text('Jaribio la maarifa'));
    await tester.tap(find.text('Jaribio la maarifa'));
    await settle(tester);
    await snap('09-paywall-phone-light');
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('release screenshots phone — community & account',
      (tester) async {
    await launchDemo(tester, viewport: const Size(390, 844));
    await startDemoShell(tester);

    await tapNavTab(tester, Icons.groups_outlined);
    await snap('10-community-phone-light');

    final postCard =
        find.byKey(const ValueKey('community-post-seed-pasheni-disease'));
    await tester.ensureVisible(postCard);
    await tester.tap(postCard);
    await settle(tester);
    await snap('11-post-detail-phone-light');
    await tester.pageBack();
    await settle(tester);

    await tapNavTab(tester, Icons.smart_toy_outlined);
    await snap('12-ai-chat-phone-light');

    await tapNavTab(tester, Icons.person_outline);
    await snap('13-profile-phone-light');

    await tester.tap(find.text('Mipangilio'));
    await settle(tester);
    await snap('14-settings-phone-light');
    await tester.pageBack();
    await settle(tester);

    await scrollToVisible(tester, find.text('Msaada / WhatsApp'));
    await tester.tap(find.text('Msaada / WhatsApp'));
    await settle(tester);
    await snap('15-whatsapp-phone-light');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('release screenshots phone — dark mode', (tester) async {
    await launchDemo(tester, viewport: const Size(390, 844));
    await startDemoShell(tester);

    await tapNavTab(tester, Icons.person_outline);
    await tester.tap(find.text('Mipangilio'));
    await settle(tester);
    await tester.tap(find.text('Giza'));
    await settle(tester, wait: const Duration(seconds: 1));
    await snap('16-settings-phone-dark');
    await tester.pageBack();
    await settle(tester);
    await tapNavTab(tester, Icons.home_outlined);
    await settle(tester);
    await snap('17-dashboard-phone-dark');
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('release screenshots tablet wide', (tester) async {
    await launchDemo(tester, viewport: const Size(900, 1200));

    await snap('21-onboarding-tablet-light');
    await startDemoShell(tester);
    await snap('22-dashboard-tablet-light');

    await tapNavTab(tester, Icons.menu_book_outlined);
    await snap('23-courses-tablet-light');

    await tapNavTab(tester, Icons.groups_outlined);
    await snap('24-community-tablet-light');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
