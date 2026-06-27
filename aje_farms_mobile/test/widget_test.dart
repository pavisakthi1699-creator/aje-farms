import 'package:flutter/material.dart';
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

  testWidgets('auth demo flow sends OTP and continues',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AjeFarmsApp());

    await tester.ensureVisible(find.text('Ingia / Jisajili'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingia / Jisajili'));
    await tester.pumpAndSettle();

    expect(find.text('Karibu tena'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '712345678');
    await tester.tap(find.text('Tuma OTP'));
    await tester.pump();

    expect(find.text('OTP ya mfano'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, '1234');
    await tester.ensureVisible(find.text('Endelea kwenye App'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endelea kwenye App'));
    await tester.pumpAndSettle();

    expect(find.text('Karibu, Mkulima'), findsOneWidget);
  });
}
