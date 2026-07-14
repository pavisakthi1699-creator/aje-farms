import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('syncSubscriptionFromAuthSession activates backend plan', () async {
    final session = AppSessionController();
    await session.restore();

    await session.syncSubscriptionFromAuthSession(
      AuthSession(
        phoneNumber: '+255712345678',
        subscriptionPlan: 'Wiki 1',
        subscriptionStartedAt: DateTime.utc(2026, 7, 2),
      ),
    );

    expect(session.hasActiveSubscription, isTrue);
    expect(session.state.subscriptionPlan, 'Wiki 1');
  });

  test('syncSubscriptionFromAuthSession clears stale local subscription',
      () async {
    final session = AppSessionController();
    await session.restore();
    await session.activateSubscription('Wiki 1');

    await session.syncSubscriptionFromAuthSession(
      const AuthSession(phoneNumber: '+255712345678'),
    );

    expect(session.hasActiveSubscription, isFalse);
    expect(session.state.subscriptionPlan, isNull);
  });

  test('signInWithPhone without a token preserves existing backend token',
      () async {
    await const FlutterSecureStorage().write(
      key: BackendSessionStorage.sessionTokenKey,
      value: 'token-existing',
    );
    final session = AppSessionController();
    await session.restore();

    await session.signInWithPhone('+255712345678');

    expect(
      await const FlutterSecureStorage()
          .read(key: BackendSessionStorage.sessionTokenKey),
      'token-existing',
    );
  });

  test('syncCompletedLessons merges backend and local completion state',
      () async {
    final session = AppSessionController();
    await session.restore();
    await session.markLessonCompleted('pasheni:maandalizi-ya-shamba');

    await session.syncCompletedLessons({
      'kuku:misingi-ya-ufugaji-wa-kuku',
    });

    expect(
      session.state.completedLessonIds,
      {
        'pasheni:maandalizi-ya-shamba',
        'kuku:misingi-ya-ufugaji-wa-kuku',
      },
    );
  });

  test('setDisplayName persists locally', () async {
    final session = AppSessionController();
    await session.restore();
    await session.startAsGuest();
    await session.setDisplayName('Asha');

    expect(session.state.displayName, 'Asha');

    final restored = AppSessionController();
    await restored.restore();
    expect(restored.state.displayName, 'Asha');
  });

  test('syncProfileFromAuthSession applies backend profile fields', () async {
    final session = AppSessionController();
    await session.restore();

    await session.syncProfileFromAuthSession(
      const AuthSession(
        phoneNumber: '+255712345678',
        displayName: 'Asha',
        preferredLocation: 'Morogoro',
      ),
    );

    expect(session.state.displayName, 'Asha');
    expect(session.state.preferredLocation, 'Morogoro');
  });

  test('syncProfileFromAuthSession clears stale local profile fields',
      () async {
    final session = AppSessionController();
    await session.restore();
    await session.setDisplayName('Asha');
    await session.setPreferredLocation('Morogoro');

    await session.syncProfileFromAuthSession(
      const AuthSession(phoneNumber: '+255712345678'),
    );

    expect(session.state.displayName, isNull);
    expect(session.state.preferredLocation, isNull);
  });
}
