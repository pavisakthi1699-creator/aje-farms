import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen-level checks for the authentication start and dark dashboard.
void main() {
  Widget buildDemoApp() => AjeFarmsApp(dependencies: AppDependencies.demo());

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('authentication start renders brand mark and form',
      (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    expect(find.byType(BrandMark), findsWidgets);
    expect(find.text('Karibu tena'), findsOneWidget);
    expect(find.text('Ingia'), findsOneWidget);
    expect(find.text('Jisajili'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme dashboard renders gradient hero without overflow',
      (tester) async {
    useTallViewport(tester);
    final session = AppSessionController();
    await session.restore();
    await session.startAsGuest();
    await session.setThemePreference(AppThemePreference.dark);

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const MainShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
    expect(find.text('Kipaumbele cha leo'), findsOneWidget);
    expect(find.text('Nyumbani'), findsOneWidget);
    expect(find.byType(AppPhoto), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
