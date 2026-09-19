import 'package:aje_farms_mobile/src/app/aje_farms_app.dart';
import 'package:aje_farms_mobile/src/app/app_dependencies.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('profile hides admin dashboard entry for non-admin',
      (tester) async {
    final session = AppSessionController();
    await session.signInWithEmail('learner@aje.test', role: 'learner');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo(),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Akaunti'));
    await tester.pumpAndSettle();

    expect(find.text('Dashibodi ya Admin'), findsNothing);
  });

  testWidgets('profile shows admin dashboard entry for admin and opens it',
      (tester) async {
    final session = AppSessionController();
    await session.signInWithEmail('admin@aje.test', role: 'admin');

    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo(),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Akaunti'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Dashibodi ya Admin'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashibodi ya Admin'), findsOneWidget);
    await tester.tap(find.text('Dashibodi ya Admin'));
    await tester.pumpAndSettle();

    expect(find.text('Dashibodi ya Admin'), findsOneWidget);
    expect(find.text('Maandishi'), findsOneWidget);
    expect(find.text('Usimamizi'), findsOneWidget);
    expect(find.text('Watumiaji'), findsOneWidget);
  });
}
