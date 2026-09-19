import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aje_farms_mobile/src/app/app_dependencies.dart';
import 'package:aje_farms_mobile/src/features/notifications/notifications_screen.dart';
import 'package:aje_farms_mobile/src/features/profile/profile_screen.dart';
import 'package:aje_farms_mobile/src/services/notification_service.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';

class _FakeNotificationService implements NotificationService {
  _FakeNotificationService(this._inbox);

  final NotificationInbox _inbox;

  @override
  Future<NotificationInbox> inbox() async => _inbox;

  @override
  Future<void> markRead({required String notificationId}) async {}

  @override
  Future<NotificationSettings> updateSettings({required bool enabled}) async {
    return NotificationSettings(
      enabled: enabled,
      communityReplies: _inbox.settings.communityReplies,
      moderationUpdates: _inbox.settings.moderationUpdates,
      learningReminders: _inbox.settings.learningReminders,
    );
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {}
}

void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'NotificationsScreen translates title and reminder tiles when English is on',
      (WidgetTester tester) async {
    final session = AppSessionController();
    await session.setLanguagePreference(const Locale('en'));

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Access pending approval'), findsOneWidget);
    expect(
      find.text(
          'When staff activates your account, courses and Mwalimu AI will unlock.'),
      findsOneWidget,
    );
    expect(find.text('New lesson added'), findsOneWidget);
    expect(
      find.text('Check out the new tomato guide and pest management.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'NotificationsScreen translates active account, assessments, and activity stats in English',
      (WidgetTester tester) async {
    final session = AppSessionController();
    await session.setLanguagePreference(const Locale('en'));
    await session.activateSubscription('Annual');
    await session.saveAssessmentScore('course-1', 85);
    await session.saveAssessmentScore('course-2', 90);
    await session.saveDocument('doc-1');
    await session.saveDocument('doc-2');
    await session.saveDocument('doc-3');
    await session.addCommunityPost(
      content: 'Hello farm',
      location: 'Arusha',
      tags: ['Kilimo'],
    );

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active Account'), findsOneWidget);
    expect(find.text('Annual is active on this device.'), findsOneWidget);
    expect(find.text('Assessment'), findsOneWidget);
    expect(
      find.text(
          'You have submitted 2 assignments. Keep using your skills on the farm.'),
      findsOneWidget,
    );
    expect(find.text('Saved Courses'), findsOneWidget);
    expect(
        find.text('You have 3 documents saved to read later.'), findsOneWidget);
    expect(find.text('Farmers Community'), findsOneWidget);
    expect(find.text('You have shared 1 posts. Check for new replies.'),
        findsOneWidget);
  });

  testWidgets(
      'NotificationsScreen translates backend inbox notifications in English',
      (WidgetTester tester) async {
    final fakeService = _FakeNotificationService(
      NotificationInbox(
        settings: const NotificationSettings(
          enabled: true,
          communityReplies: true,
          moderationUpdates: true,
          learningReminders: true,
        ),
        notifications: [
          AppNotification(
            id: 'notif-1',
            type: 'community_reply',
            title: 'Jibu jipya kwenye jamii',
            body: 'Mkulima amejibu post yako.',
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: 'notif-2',
            type: 'moderation_update',
            title: 'Post imefichwa',
            body:
                'Post yako imefichwa baada ya ukaguzi wa timu ya Chuo Kikuu Cha Mtaani.',
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: 'notif-3',
            type: 'community_reply',
            title: 'Jibu jipya',
            body: 'Asha amejibu post yako.',
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );

    final session = AppSessionController();
    await session.setLanguagePreference(const Locale('en'));
    await session.signInWithEmail('mkulima@demo.aje');

    final demoDeps = AppDependencies.demo();
    final deps = AppDependencies(
      learningRepository: demoDeps.learningRepository,
      communityRepository: demoDeps.communityRepository,
      subscriptionRepository: demoDeps.subscriptionRepository,
      mwalimuAiService: demoDeps.mwalimuAiService,
      authService: demoDeps.authService,
      catalogService: demoDeps.catalogService,
      adminService: demoDeps.adminService,
      communityService: demoDeps.communityService,
      learningProgressService: demoDeps.learningProgressService,
      notificationService: fakeService,
      paymentService: demoDeps.paymentService,
      searchService: demoDeps.searchService,
      offlineSearchService: demoDeps.offlineSearchService,
      refreshCatalog: () async {},
    );

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: deps,
        child: AppSessionScope(
          controller: session,
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Notifications enabled'), findsOneWidget);
    expect(find.text('New community reply'), findsOneWidget);
    expect(find.text('A farmer replied to your post.'), findsOneWidget);
    expect(find.text('Post hidden'), findsOneWidget);
    expect(
      find.text(
          'Your post was hidden after review by the Mtaani Open University team.'),
      findsOneWidget,
    );
    expect(find.text('New reply'), findsOneWidget);
    expect(find.text('Asha replied to your post.'), findsOneWidget);
    expect(find.text('Read'), findsNWidgets(3));
  });

  testWidgets(
      'SettingsScreen translates notification preference switch when English is on',
      (WidgetTester tester) async {
    useTallViewport(tester);
    final session = AppSessionController();
    await session.setLanguagePreference(const Locale('en'));

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: session,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    expect(find.text('Learning and community notifications'), findsOneWidget);
    expect(find.text('Turn reminders on or off in the app.'), findsOneWidget);
  });
}
