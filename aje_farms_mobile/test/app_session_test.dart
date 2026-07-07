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
}
