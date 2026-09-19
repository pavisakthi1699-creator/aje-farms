import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('expanded community uses a list at 2x text without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = AppSessionController();
    await session.restore();
    await session.startAsGuest();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: AppDependenciesScope(
          dependencies: AppDependencies.demo(),
          child: AppSessionScope(
            controller: session,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const CommunityScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SliverGrid), findsNothing);
    expect(find.byType(CommunityPostCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
