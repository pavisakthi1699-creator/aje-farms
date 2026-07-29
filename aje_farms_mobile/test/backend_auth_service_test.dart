import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// signUp/signIn/signOut/sendPasswordResetEmail/updatePassword call the
// Supabase Flutter SDK directly rather than the AJE backend, so they aren't
// covered by this MockClient-based harness — that's Supabase's own tested
// code path. What's tested here is everything BackendAuthService still owns:
// reading the resulting profile/role/accountStatus from the AJE backend.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('loads the current user session with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3000/api/users/me');
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"user":{"id":"user-1","email":"farmer@aje.test","role":"learner","accountStatus":"active","subscriptionPlan":"Wiki 1","subscriptionStartedAt":"2026-07-02T10:00:00.000Z"}}',
          200,
        );
      }),
    );

    final session = await service.getSession();

    expect(session.email, 'farmer@aje.test');
    expect(session.userId, 'user-1');
    expect(session.subscriptionPlan, 'Wiki 1');
    expect(session.hasActiveAccess, isTrue);
  });

  test('throws typed exception for backend auth errors', () {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Kikao kimeisha."}', 401);
      }),
    );

    expect(
      () => service.getSession(),
      throwsA(isA<AuthException>()),
    );
  });

  test('updates backend profile with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/profile',
        );
        expect(request.body, contains('"displayName":"Asha"'));
        return http.Response(
          '{"user":{"id":"user-1","email":"farmer@aje.test","role":"learner","accountStatus":"active","displayName":"Asha","preferredLocation":"Morogoro","subscriptionPlan":null,"subscriptionStartedAt":null}}',
          200,
        );
      }),
    );

    final session = await service.updateProfile(
      displayName: 'Asha',
      preferredLocation: 'Morogoro',
    );

    expect(session.displayName, 'Asha');
    expect(session.preferredLocation, 'Morogoro');
  });

  test('cancels backend subscription with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/subscription/cancel',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"user":{"id":"user-1","email":"farmer@aje.test","role":"learner","accountStatus":"active","subscriptionPlan":null,"subscriptionStartedAt":null}}',
          200,
        );
      }),
    );

    final session = await service.cancelSubscription();

    expect(session.email, 'farmer@aje.test');
    expect(session.subscriptionPlan, isNull);
  });

  test('loads admin diagnostics with bearer token', () async {
    await BackendSessionStorage.writeToken('token-admin');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://localhost:3000/api/auth/whoami');
        expect(request.headers['Authorization'], 'Bearer token-admin');
        return http.Response(
          '{"user":{"email":"admin@aje.test"},"role":"admin","hasAdminAccess":true,"allowlistedAdmin":true,"source":"email_allowlist"}',
          200,
        );
      }),
    );

    final diagnostics = await service.getAdminAccessDiagnostics();

    expect(diagnostics.email, 'admin@aje.test');
    expect(diagnostics.role, 'admin');
    expect(diagnostics.hasAdminAccess, isTrue);
    expect(diagnostics.allowlistedAdmin, isTrue);
    expect(diagnostics.source, 'email_allowlist');
  });
}
