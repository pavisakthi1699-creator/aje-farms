import 'package:flutter_test/flutter_test.dart';

import 'package:aje_farms_mobile/src/app.dart';

void main() {
  testWidgets('renders AJE Farms onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const AjeFarmsApp());

    expect(find.text('AJE Farms'), findsOneWidget);
    expect(find.text('Kilimo na Ujasiliamali'), findsOneWidget);
    expect(find.text('Anza Sasa'), findsOneWidget);
  });

  testWidgets('starts the main learner shell', (WidgetTester tester) async {
    await tester.pumpWidget(const AjeFarmsApp());

    await tester.tap(find.text('Anza Sasa'));
    await tester.pumpAndSettle();

    expect(find.text('Karibu, Mkulima'), findsOneWidget);
    expect(find.text('Una changamoto gani leo?'), findsOneWidget);
  });
}
