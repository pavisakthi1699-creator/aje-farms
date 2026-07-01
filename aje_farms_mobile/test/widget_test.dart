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
    expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
    expect(find.text('Jaribio linaendelea'), findsOneWidget);
  });

  testWidgets('guides farmer from home problem intake into AI chat',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AjeFarmsApp());

    await tester.tap(find.text('Anza Sasa'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eleza Tatizo'));
    await tester.pumpAndSettle();

    expect(find.text('Zao au mnyama (hiari)'), findsOneWidget);
    expect(find.text('Magonjwa ya mimea'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nyanya');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final plantDiseaseTile =
        find.byKey(const ValueKey('problem-category-Magonjwa ya mimea'));
    await tester.ensureVisible(plantDiseaseTile);
    await tester.tap(plantDiseaseTile);
    await tester.pumpAndSettle();

    expect(find.text('Muktadha uliotumwa'), findsOneWidget);
    expect(find.text('Magonjwa ya mimea - nyanya'), findsOneWidget);
    expect(find.textContaining('Zao/mnyama: nyanya'), findsOneWidget);
    expect(find.textContaining('Kwa nyanya'), findsOneWidget);
    expect(find.text('Ona Kwenye Mafunzo'), findsOneWidget);
    expect(find.text('Msaidizi wa Binadamu'), findsOneWidget);
  });

  testWidgets('continues a course and opens lesson and premium states',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AjeFarmsApp());

    await tester.tap(find.text('Anza Sasa'));
    await tester.pumpAndSettle();

    final dashboardCourse =
        find.byKey(const ValueKey('dashboard-course-tap-pasheni'));
    await tester.scrollUntilVisible(dashboardCourse, 220);
    await tester.tap(dashboardCourse);
    await tester.pumpAndSettle();

    expect(find.text('Mwendelezo wa kozi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Maandalizi ya shamba'), 220);
    expect(find.text('Maandalizi ya shamba'), findsOneWidget);
    expect(find.text('Umekamilisha'), findsWidgets);

    await tester.tap(find.text('Maandalizi ya shamba'));
    await tester.pumpAndSettle();

    expect(find.text('Fungua Somo la Mfano'), findsOneWidget);
    expect(find.textContaining('Tambua eneo'), findsOneWidget);

    await tester.tap(find.text('Fungua Somo la Mfano'));
    await tester.pump();

    expect(find.textContaining('Video: Maandalizi ya shamba'), findsOneWidget);

    await tester.ensureVisible(find.text('Jaribio la maarifa'));
    await tester.tap(find.text('Jaribio la maarifa'));
    await tester.pumpAndSettle();

    expect(find.text('Muda wa jaribio umeisha'), findsOneWidget);
  });

  testWidgets('opens community discussion and replies with AI handoff',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AjeFarmsApp());

    await tester.tap(find.text('Anza Sasa'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Jamii hai leo'), findsOneWidget);
    expect(
        find.text(
            'Naomba ushauri, majani ya pasheni yangu yanabadilika rangi.'),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('community-filter-Magonjwa')));
    await tester.pumpAndSettle();

    expect(find.text('Inahitaji haraka'), findsOneWidget);
    expect(find.text('Natafuta mwongozo wa kuanza ufugaji wa kuku wa nyama.'),
        findsNothing);

    await tester.tap(find
        .text('Naomba ushauri, majani ya pasheni yangu yanabadilika rangi.'));
    await tester.pumpAndSettle();

    expect(find.text('Majadiliano'), findsOneWidget);
    expect(find.text('Hatua inayofuata'), findsOneWidget);

    await tester.enterText(find.byType(TextField),
        'Nitapunguza maji na kuangalia chini ya majani.');
    await tester.tap(find.byKey(const ValueKey('community-send-reply')));
    await tester.pumpAndSettle();

    expect(find.text('Jibu limehifadhiwa kwenye demo.'), findsOneWidget);

    await tester.ensureVisible(find.text('Fupisha na AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fupisha na AI'));
    await tester.pumpAndSettle();

    expect(find.text('Muktadha uliotumwa'), findsOneWidget);
    expect(find.text('Jamii'), findsOneWidget);
  });

  testWidgets('selects a plan and completes demo mobile money checkout',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));

    expect(find.text('Mwalimu AI bila kikomo'), findsOneWidget);

    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('plan-Wiki 1')), 220);
    await tester.tap(find.byKey(const ValueKey('plan-Wiki 1')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-method-Tigo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0712345678');

    await tester.ensureVisible(find.text('Wiki 1 kupitia Tigo'));
    expect(find.text('Wiki 1 kupitia Tigo'), findsOneWidget);
    expect(find.text('TZS 3,000'), findsWidgets);

    await tester.ensureVisible(find.text('Lipa TZS 3,000'));
    await tester.tap(find.text('Lipa TZS 3,000'));
    await tester.pump();

    expect(find.text('Inasubiri uthibitisho...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Malipo Yamefanikiwa!'), findsOneWidget);
    expect(
        find.textContaining('Wiki 1 imewashwa kupitia Tigo'), findsOneWidget);
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
