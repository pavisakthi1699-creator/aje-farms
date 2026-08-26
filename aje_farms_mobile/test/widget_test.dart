import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aje_farms_mobile/src/app.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';

import 'support/stub_auth_service.dart';

/// Stands in for the backend rejecting a learner whose account no admin has
/// verified yet (`/api/mwalimu-chat` answers 403).
class _UnverifiedMwalimuAiService implements MwalimuAiService {
  @override
  Future<MwalimuAiAnswer> answer(String prompt) async {
    throw const MwalimuAiException(
      'Ufikiaji wa mafunzo unahitaji malipo yaliyoidhinishwa na admin.',
      statusCode: 403,
    );
  }

  @override
  Future<void> reportAnswer(
    String messageId, {
    required String reason,
    String? details,
  }) async {}
}

class _RecordingCommunityService extends LocalCommunityService {
  List<String>? submittedTags;

  @override
  Future<CommunityPost> createPost({
    required String content,
    required String location,
    required List<String> tags,
    String? imagePath,
  }) async {
    submittedTags = tags;
    return super.createPost(
      content: content,
      location: location,
      tags: tags,
      imagePath: imagePath,
    );
  }
}

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
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'mkulima@demo.aje');
    await tester.enterText(find.byType(EditableText).at(1), 'nenosiri');
    await tester.ensureVisible(find.text('Ingia Sasa'));
    await tester.tap(find.text('Ingia Sasa'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('renders authentication on a fresh launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Chuo Kikuu Cha Mtaani'), findsOneWidget);
    expect(find.text('Karibu tena'), findsOneWidget);
    expect(find.text('Ingia'), findsOneWidget);
    expect(find.text('Jisajili'), findsOneWidget);
    expect(find.text('Nyumbani'), findsNothing);
  });

  testWidgets('starts the main learner shell', (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());

    await startDemoShell(tester);

    expect(find.textContaining('Karibu'), findsOneWidget);
    expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
    // The demo auth service returns an already-verified account, so the card
    // reports active access rather than prompting for a package.
    expect(find.text('Akaunti yako imewashwa'), findsOneWidget);
  });

  testWidgets(
      'an unverified learner asking Mwalimu AI is sent to membership status, '
      'not told the network failed', (WidgetTester tester) async {
    useTallViewport(tester);
    final session = AppSessionController();
    await session.signInWithEmail('mkulima@aje.test');
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          mwalimuAiService: _UnverifiedMwalimuAiService(),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    // Both the dashboard shortcut and the nav destination carry this label.
    await tester.tap(find.text('Uliza AI').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Nyanya zangu ni?');
    await tester.tap(find.byTooltip('Tuma'));
    await tester.pumpAndSettle();

    // The 403 opens the membership status screen so the learner has somewhere
    // to go instead of retrying a request that cannot succeed.
    expect(find.text('Hali ya Uanachama'), findsOneWidget);

    // The chat itself sits under the pushed route, so look offstage: the reply
    // must name verification rather than blame the connection.
    expect(
      find.textContaining('kuthibitisha akaunti', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('tatizo la kimtandao', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets(
      'a newly registered learner is told an admin must verify the account',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = AppSessionController();
    await session.signInWithEmail('mkulima@aje.test');
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('pending_activation'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    // Registering is not access: the learner is held at the wall (see
    // AccessGate) rather than shown a shell whose lessons are all blank.
    expect(find.text('Akaunti yako inasubiri uthibitisho'), findsOneWidget);
    expect(
      find.text(
        'Umesajiliwa. Timu ya Chuo Kikuu Cha Mtaani itathibitisha akaunti yako '
        'ili kufungua mafunzo.',
      ),
      findsOneWidget,
    );
    // Access is granted by staff, never bought in-app, so the card must not
    // send a pending learner looking for a package to choose.
    expect(find.textContaining('Chagua kifurushi'), findsNothing);
    // The registration prompt belongs to signed-out guests only.
    expect(
      find.text('Jisajili ili kuona mafunzo yanayopatikana.'),
      findsNothing,
    );
  });

  testWidgets(
      'a suspended account is named as suspended, never as ordinary '
      'access', (WidgetTester tester) async {
    useTallViewport(tester);
    final session = AppSessionController();
    await session.signInWithEmail('msimamizi@aje.test');
    await session.syncAccountStatusFromAuthSession(
      const AuthSession(
          email: 'msimamizi@aje.test', accountStatus: 'suspended'),
    );
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          authService: StubAuthService('suspended'),
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    // Status wording used to be derived per screen from subscriptionPlan, so a
    // suspended account was told it had ordinary access on one card and was
    // suspended on the next. Everything now derives from AccountAccessStatus,
    // and a suspended account meets the wall instead of the shell.
    expect(find.text('Imesitishwa'), findsOneWidget);
    expect(find.text('Ufikiaji wa kawaida'), findsNothing);
    expect(
      find.textContaining('Unaweza kusoma mafunzo ya msingi'),
      findsNothing,
    );
  });

  testWidgets('a guest dashboard prompts registration instead of local lessons',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = AppSessionController();
    await session.startAsGuest();
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo(),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Jisajili ili kuona mafunzo yanayopatikana.'),
      findsOneWidget,
    );
    expect(find.textContaining('yamehifadhiwa kwenye kifaa'), findsNothing);
  });

  testWidgets('guest state does not show a protected-catalog refresh failure',
      (WidgetTester tester) async {
    useTallViewport(tester);
    const fallback = DemoAppRepository();
    final cachedRepository = CachedAppRepository(
      learningSeed: fallback,
      communitySeed: fallback,
      subscriptionSeed: fallback,
    );
    await cachedRepository.refresh(_FailingCatalogService());
    final demo = AppDependencies.demo();
    final dependencies = AppDependencies(
      learningRepository: cachedRepository,
      communityRepository: cachedRepository,
      subscriptionRepository: cachedRepository,
      mwalimuAiService: demo.mwalimuAiService,
      authService: demo.authService,
      catalogService: demo.catalogService,
      adminService: demo.adminService,
      communityService: demo.communityService,
      learningProgressService: demo.learningProgressService,
      notificationService: demo.notificationService,
      paymentService: demo.paymentService,
      searchService: demo.searchService,
      offlineSearchService: demo.offlineSearchService,
      refreshCatalog: () => cachedRepository.refresh(_FailingCatalogService()),
      refreshListenable: cachedRepository,
    );
    final session = AppSessionController();
    await session.startAsGuest();

    await tester.pumpWidget(
      AjeFarmsApp(dependencies: dependencies, sessionController: session),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Imeshindikana kusasisha maudhui mapya. Unaona taarifa za hivi karibuni.'),
      findsNothing,
    );
    expect(
      find.text('Jisajili ili kuona mafunzo yanayopatikana.'),
      findsOneWidget,
    );
  });

  testWidgets('opens a course by tapping its catalog card',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final course = AppDependencies.demo().learningRepository.courses.first;
    await tester.pumpWidget(buildDemoApp());
    await startDemoShell(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.menu_book_outlined),
      ),
    );
    await tester.pumpAndSettle();

    final courseTitle = find.text(course.title);
    await tester.scrollUntilVisible(
      courseTitle,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(courseTitle);
    await tester.pumpAndSettle();

    expect(find.text('Mwendelezo wa kozi'), findsOneWidget);
    expect(find.text('Masomo'), findsOneWidget);

    final firstLesson = find.text(course.lessons.first.title);
    await tester.ensureVisible(firstLesson);
    await tester.pumpAndSettle();
    await tester.tap(firstLesson);
    await tester.pumpAndSettle();

    expect(find.text('Kamilisha Somo'), findsOneWidget);
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

  testWidgets('continues a course and completes a reading lesson',
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
    await tester.scrollUntilVisible(find.text('Kuchagua eneo la shamba'), 220);
    expect(find.text('Kuchagua eneo la shamba'), findsOneWidget);
    expect(find.text('Bado hujaanza'), findsWidgets);

    await tester.tap(find.text('Kuchagua eneo la shamba'));
    await tester.pumpAndSettle();

    expect(find.text('Kamilisha Somo'), findsOneWidget);
    expect(find.textContaining('Chunguza mwanga'), findsOneWidget);

    await tester.tap(find.text('Kamilisha Somo'));
    await tester.pump();

    expect(
        find.textContaining('Somo: Kuchagua eneo la shamba'), findsOneWidget);
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

    expect(find.text('Jamii ya Chuo Kikuu Cha Mtaani'), findsOneWidget);
    expect(
        find.text(
            'Karibu kwenye jamii ya Chuo Kikuu Cha Mtaani. Eleza hali uliyoiona, eneo na zao au mnyama. Usishiriki taarifa binafsi, na thibitisha ushauri wa dawa au chanjo na mtaalamu wa eneo lako.'),
        findsOneWidget);

    final postCard =
        find.byKey(const ValueKey('community-post-seed-community-guidelines'));
    await tester.ensureVisible(postCard);
    await tester.tap(postCard);
    await tester.pumpAndSettle();

    expect(find.text('Majadiliano'), findsOneWidget);
    await tester.ensureVisible(find.text('Hatua inayofuata'));
    expect(find.text('Hatua inayofuata'), findsOneWidget);

    await tester.enterText(find.byType(TextField),
        'Nimeandika eneo, zao na dalili ili kumuuliza mtaalamu.');
    await tester.tap(find.byKey(const ValueKey('community-send-reply')));
    await tester.pumpAndSettle();

    expect(find.text('Jibu limehifadhiwa.'), findsOneWidget);

    await tester.ensureVisible(find.text('Andaa muhtasari'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Andaa muhtasari'));
    await tester.pumpAndSettle();

    expect(find.text('Muktadha uliotumwa'), findsOneWidget);
    expect(find.text('Jamii'), findsOneWidget);
  });

  testWidgets('awaiting-activation screen is strict consumption-only',
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

    // No payment method, purchase instructions, or support link that could
    // steer a locked learner to an external transaction.
    expect(find.text('Akaunti bado haijawashwa'), findsOneWidget);
    expect(find.text('Ufikiaji wa Mwalimu AI'), findsOneWidget);
    expect(find.text('Onyesha Hali Upya'), findsOneWidget);
    expect(find.text('Programu hii haitoi ununuzi ndani ya programu.'),
        findsOneWidget);
    expect(find.text('Pata Msaada wa Akaunti'), findsNothing);
    expect(find.text('Wiki 1'), findsNothing);
    expect(find.text('TZS 3,000'), findsNothing);
  });

  testWidgets('notifications do not direct locked learners to purchase access',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: AppSessionController(),
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      ),
    );

    expect(find.text('Ufikiaji unasubiri idhini'), findsOneWidget);
    expect(find.textContaining('Lipia'), findsNothing);
    expect(find.textContaining('TZS'), findsNothing);
  });

  testWidgets('auth demo flow signs in with email and password',
      (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Karibu tena'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).at(0),
      'mkulima@demo.aje',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.ensureVisible(find.text('Ingia Sasa'));
    await tester.tap(find.text('Ingia Sasa'));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
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

  testWidgets('submits only currently configured community topics',
      (WidgetTester tester) async {
    useTallViewport(tester);
    const fallback = DemoAppRepository();
    final cachedRepository = CachedAppRepository(
      learningSeed: fallback,
      communitySeed: fallback,
      subscriptionSeed: fallback,
    );
    final communityService = _RecordingCommunityService();
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies.demo().copyWith(
          communityRepository: cachedRepository,
          communityService: communityService,
        ),
      ),
    );
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
      'Ninatafuta ushauri wa matunda kwa shamba langu la nyumbani.',
    );
    await tester.enterText(find.byType(TextField).last, 'Morogoro');

    cachedRepository.replaceCommunityTopics(['Matunda']);
    await tester.tap(find.text('Tuma kwenye Jamii'));
    await tester.pumpAndSettle();

    expect(communityService.submittedTags, ['Matunda']);
  });

  testWidgets('keeps reading lessons available when subscription is active',
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

    await tester.scrollUntilVisible(find.text('Kuchagua eneo la shamba'), 220);
    await tester.tap(find.text('Kuchagua eneo la shamba'));
    await tester.pumpAndSettle();

    expect(find.text('Muda wa jaribio umeisha'), findsNothing);
    expect(find.text('Kamilisha Somo'), findsOneWidget);
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

      expect(find.textContaining('Karibu'), findsOneWidget);
      expect(find.text('Eleza tatizo la shamba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('trending topic opens AI chat with topic context',
      (WidgetTester tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(buildDemoApp());
    await startDemoShell(tester);

    await tester.scrollUntilVisible(
      find.text('Matunda na Mbogamboga'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matunda na Mbogamboga'));
    await tester.pumpAndSettle();

    expect(find.text('Mwalimu AI'), findsWidgets);
    expect(find.text('Muktadha uliotumwa'), findsOneWidget);
    expect(find.text('Matunda na Mbogamboga'), findsWidgets);
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

class _FailingCatalogService implements CatalogService {
  @override
  Future<CatalogSnapshot> loadCatalog() async {
    throw const CatalogException('Authentication required.');
  }

  @override
  Future<String> lessonVideoUrl(String lessonId) async => '';
}
