import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('syncAccountStatusFromAuthSession activates backend plan', () async {
    final session = AppSessionController();
    await session.restore();

    await session.syncAccountStatusFromAuthSession(
      AuthSession(
        email: 'farmer@aje.test',
        accountStatus: 'active',
        subscriptionPlan: 'Wiki 1',
        subscriptionStartedAt: DateTime.utc(2026, 7, 2),
      ),
    );

    expect(session.hasActiveAccess, isTrue);
    expect(session.state.subscriptionPlan, 'Wiki 1');
  });

  test('syncAccountStatusFromAuthSession clears stale local subscription',
      () async {
    final session = AppSessionController();
    await session.restore();
    await session.activateSubscription('Wiki 1');

    await session.syncAccountStatusFromAuthSession(
      const AuthSession(email: 'farmer@aje.test', accountStatus: 'pending_activation'),
    );

    expect(session.hasActiveAccess, isFalse);
    expect(session.state.subscriptionPlan, isNull);
  });

  // The server grants learning access on `userHasAdminAccess(user) ||
  // hasActiveEntitlement(...)`, so an admin reaches content without an
  // entitlement. The client checked only accountStatus, so a staff account
  // with no entitlement was shown as suspended and locked out of the very
  // content the API would have served it.
  test('an admin has access even without an entitlement', () async {
    final session = AppSessionController();
    await session.signInWithEmail('msimamizi@aje.test', role: 'admin');
    await session.syncAccountStatusFromAuthSession(
      const AuthSession(
        email: 'msimamizi@aje.test',
        role: 'admin',
        accountStatus: 'suspended',
      ),
    );

    expect(session.state.isAdmin, isTrue);
    expect(session.hasActiveAccess, isTrue);
  });

  test('a learner without an entitlement still has no access', () async {
    final session = AppSessionController();
    await session.signInWithEmail('mkulima@aje.test');
    await session.syncAccountStatusFromAuthSession(
      const AuthSession(email: 'mkulima@aje.test', accountStatus: 'suspended'),
    );

    expect(session.hasActiveAccess, isFalse);
  });

  test('signInWithEmail records the signed-in identity', () async {
    final session = AppSessionController();
    await session.restore();

    await session.signInWithEmail('farmer@aje.test', role: 'learner');

    expect(session.isSignedIn, isTrue);
    expect(session.email, 'farmer@aje.test');
    expect(session.state.role, 'learner');
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
        email: 'farmer@aje.test',
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
      const AuthSession(email: 'farmer@aje.test'),
    );

    expect(session.state.displayName, isNull);
    expect(session.state.preferredLocation, isNull);
  });
}
