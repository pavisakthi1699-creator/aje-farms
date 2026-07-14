import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aje_farms_mobile/src/app.dart';

void main() {
  Widget buildDemoApp() {
    return AjeFarmsApp(dependencies: AppDependencies.demo());
  }

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> startDemoShell(WidgetTester tester) async {
    await tester.tap(find.text('Anza Sasa'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('renders AJE Farms onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(buildDemoApp());

    expect(find.text('AJE Farms'), findsOneWidget);
    expect(find.text('Kilimo na Ujasiliamali'), findsOneWidget);
    expect(find.text('Anza Sasa'), findsOneWidget);
  });

  testWidgets('starts the main learner shell', (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());

    await startDemoShell(tester);

    expect(find.text('Karibu, Mkulima'), findsOneWidget);
    expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
    expect(find.text('Jaribio linaendelea'), findsOneWidget);
  });

  testWidgets('guides farmer from home problem intake into AI chat',
      (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());

    await startDemoShell(tester);

    await tester.tap(find.text('Eleza tatizo'));
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
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());

    await startDemoShell(tester);

    final dashboardCourse =
        find.byKey(const ValueKey('dashboard-course-tap-pasheni'));
    await tester.ensureVisible(dashboardCourse);
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
    useTallViewport(tester);

    await tester.pumpWidget(buildDemoApp());

    await startDemoShell(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.groups_outlined),
      ),
    );
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

    final postCard =
        find.byKey(const ValueKey('community-post-seed-pasheni-disease'));
    await tester.ensureVisible(postCard);
    await tester.tap(postCard);
    await tester.pumpAndSettle();

    expect(find.text('Majadiliano'), findsOneWidget);
    await tester.ensureVisible(find.text('Hatua inayofuata'));
    expect(find.text('Hatua inayofuata'), findsOneWidget);

    await tester.enterText(find.byType(TextField),
        'Nitapunguza maji na kuangalia chini ya majani.');
    await tester.tap(find.byKey(const ValueKey('community-send-reply')));
    await tester.pumpAndSettle();

    expect(find.text('Jibu limehifadhiwa.'), findsOneWidget);

    await tester.ensureVisible(find.text('Fupisha na AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fupisha na AI'));
    await tester.pumpAndSettle();

    expect(find.text('Muktadha uliotumwa'), findsOneWidget);
    expect(find.text('Jamii'), findsOneWidget);
  });

  testWidgets('selects a plan and completes demo mobile money checkout',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: AppSessionController(),
          child: const MaterialApp(home: PaywallScreen()),
        ),
      ),
    );

    expect(find.text('Mwalimu AI bila kikomo'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('plan-Wiki 1')));
    await tester.pumpAndSettle();
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
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());

    await tester.ensureVisible(find.text('Ingia / Jisajili'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingia / Jisajili'));
    await tester.pumpAndSettle();

    expect(find.text('Karibu tena'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '712345678');
    await tester.ensureVisible(find.text('Tuma OTP'));
    await tester.tap(find.text('Tuma OTP'));
    await tester.pumpAndSettle();

    expect(find.text('OTP'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, '1234');
    await tester.ensureVisible(find.text('Endelea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endelea'));
    await tester.pumpAndSettle();

    expect(find.text('Karibu tena'), findsOneWidget);
  });

  testWidgets('creates a local community post', (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());

    await startDemoShell(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.groups_outlined),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Majani ya nyanya yana madoa ya njano na nataka ushauri.',
    );
    await tester.enterText(find.byType(TextField).last, 'Morogoro');
    await tester.tap(find.text('Nyanya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuma kwenye Jamii'));
    await tester.pumpAndSettle();

    expect(find.text('Post imetumwa kwenye jamii.'), findsOneWidget);
    expect(
      find.text('Majani ya nyanya yana madoa ya njano na nataka ushauri.'),
      findsOneWidget,
    );
  });

  testWidgets('opens premium lesson when subscription is active',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = AppSessionController();
    await session.restore();
    await session.startAsGuest();
    await session.activateSubscription('Wiki 1');
    final course = AppDependencies.demo()
        .learningRepository
        .courses
        .firstWhere((item) => item.id == 'pasheni');

    await tester.pumpWidget(
      MaterialApp(
        home: AppDependenciesScope(
          dependencies: AppDependencies.demo(),
          child: AppSessionScope(
            controller: session,
            child: CourseDetailScreen(course: course),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Jaribio la maarifa'), 220);
    await tester.tap(find.text('Jaribio la maarifa'));
    await tester.pumpAndSettle();

    expect(find.text('Muda wa jaribio umeisha'), findsNothing);
    expect(find.text('Fungua Somo la Mfano'), findsOneWidget);
  });

  testWidgets('dashboard remains usable at large text scale',
      (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());
    await startDemoShell(tester);

    for (final scale in [1.3, 2.0]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: buildDemoApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Karibu, Mkulima'), findsOneWidget);
      expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('trending topic opens AI chat with topic context',
      (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());
    await startDemoShell(tester);

    await tester.ensureVisible(find.text('Maji'));
    await tester.tap(find.text('Maji'));
    await tester.pumpAndSettle();

    expect(find.text('Mwalimu AI'), findsWidgets);
    expect(find.text('Muktadha uliotumwa'), findsOneWidget);
    expect(find.text('Maji'), findsWidgets);
  });

  testWidgets('bottom navigation shows Swahili labels',
      (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());
    await startDemoShell(tester);

    final navBar = find.byType(NavigationBar);
    expect(find.descendant(of: navBar, matching: find.text('Nyumbani')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Mafunzo')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Uliza AI')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Jamii')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Akaunti')),
        findsOneWidget);
  });

  testWidgets('compact phone navigation renders without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = AppSessionController();
    await session.restore();
    await session.startAsGuest();

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: const MaterialApp(home: MainShell()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nyumbani'), findsOneWidget);
    expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone navigation at 2x text has no overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
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
            child: const MaterialApp(home: MainShell()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nyumbani'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Eleza tatizo la shamba'),
      120,
    );
    expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
