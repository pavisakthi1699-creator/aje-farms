import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the development OTP in an internal build', (tester) async {
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: AppSessionController(),
          child: const MaterialApp(home: AuthScreen()),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText).first, '712345678');
    await tester.tap(find.text('Tuma OTP'));
    await tester.pumpAndSettle();

    expect(find.text('OTP ya majaribio: 1234'), findsOneWidget);
  });
}
