import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _surfaceKey = ValueKey('golden-surface');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('onboarding visual baseline', (tester) async {
    await _useViewport(tester, const Size(390, 844));
    await _pumpGoldenSurface(
      tester,
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: AppSessionController(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(useBrandFont: false),
            home: const OnboardingScreen(),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(_surfaceKey),
      matchesGoldenFile('goldens/onboarding_phone_light.png'),
    );
  }, tags: const ['golden']);

  testWidgets('dashboard visual baseline', (tester) async {
    await _useViewport(tester, const Size(390, 844));
    final session = await _guestSession();

    await _pumpGoldenSurface(
      tester,
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(useBrandFont: false),
            home: const MainShell(),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(_surfaceKey),
      matchesGoldenFile('goldens/dashboard_phone_light.png'),
    );
  }, tags: const ['golden']);

  testWidgets('dashboard dark visual baseline', (tester) async {
    await _useViewport(tester, const Size(390, 844));
    final session = await _guestSession();

    await _pumpGoldenSurface(
      tester,
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(useBrandFont: false),
            home: const MainShell(),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(_surfaceKey),
      matchesGoldenFile('goldens/dashboard_phone_dark.png'),
    );
  }, tags: const ['golden']);

  testWidgets('compact large-text dashboard visual baseline', (tester) async {
    await _useViewport(tester, const Size(320, 640));
    final session = await _guestSession();

    await _pumpGoldenSurface(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: AppDependenciesScope(
          dependencies: AppDependencies.demo(),
          child: AppSessionScope(
            controller: session,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(useBrandFont: false),
              home: const MainShell(),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(_surfaceKey),
      matchesGoldenFile('goldens/dashboard_compact_large_text.png'),
    );
  }, tags: const ['golden']);
}

Future<AppSessionController> _guestSession() async {
  final session = AppSessionController();
  await session.restore();
  await session.startAsGuest();
  return session;
}

Future<void> _useViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpGoldenSurface(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _surfaceKey,
      child: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
