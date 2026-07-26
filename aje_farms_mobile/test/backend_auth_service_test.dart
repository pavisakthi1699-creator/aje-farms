import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('requests an OTP challenge from backend', () async {
    late http.Request capturedRequest;
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"challengeId":"abc","message":"OTP imetumwa","debugOtp":"1234"}',
          200,
        );
      }),
    );

    final challenge = await service.requestOtp('+255 712345678');

    expect(challenge.challengeId, 'abc');
    expect(challenge.message, 'OTP imetumwa');
    expect(challenge.debugOtp, '1234');
    expect(capturedRequest.url.toString(),
        'http://localhost:3000/api/auth/request-otp');
    expect(capturedRequest.body, contains('+255 712345678'));
  });

  test('verifies an OTP challenge with backend', () async {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.url.toString(),
            'http://localhost:3000/api/auth/verify-otp');
        expect(request.body, contains('"otp":"1234"'));
        return http.Response(
          '{"phoneNumber":"+255712345678","sessionToken":"token-abc","user":{"id":"user-1","phoneNumber":"+255712345678","role":"learner","subscriptionPlan":"Mwezi 1","subscriptionStartedAt":"2026-07-02T10:00:00.000Z"}}',
          200,
        );
      }),
    );

    final session = await service.verifyOtp(
      phoneNumber: '+255 712345678',
      otp: '1234',
      challengeId: 'abc',
    );

    expect(session.phoneNumber, '+255712345678');
    expect(session.sessionToken, 'token-abc');
    expect(session.userId, 'user-1');
    expect(session.role, 'learner');
    expect(session.subscriptionPlan, 'Mwezi 1');
    expect(session.hasActiveSubscription, isTrue);
    expect(session.subscriptionStartedAt, isNotNull);
  });

  test('throws typed exception for backend auth errors', () {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"OTP si sahihi"}', 401);
      }),
    );

    expect(
      () => service.requestOtp('+255 712345678'),
      throwsA(isA<AuthException>()),
    );
  });

  test('loads a backend user session by phone with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/by-phone/%2B255712345678',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"user":{"id":"user-1","phoneNumber":"+255712345678","role":"learner","subscriptionPlan":"Wiki 1","subscriptionStartedAt":"2026-07-02T10:00:00.000Z"}}',
          200,
        );
      }),
    );

    final session = await service.getSession('+255712345678');

    expect(session.phoneNumber, '+255712345678');
    expect(session.subscriptionPlan, 'Wiki 1');
  });

  test('updates backend profile by phone with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/by-phone/%2B255712345678/profile',
        );
        expect(request.body, contains('"displayName":"Asha"'));
        return http.Response(
          '{"user":{"id":"user-1","phoneNumber":"+255712345678","role":"learner","displayName":"Asha","preferredLocation":"Morogoro","subscriptionPlan":null,"subscriptionStartedAt":null}}',
          200,
        );
      }),
    );

    final session = await service.updateProfile(
      phoneNumber: '+255712345678',
      displayName: 'Asha',
      preferredLocation: 'Morogoro',
    );

    expect(session.displayName, 'Asha');
    expect(session.preferredLocation, 'Morogoro');
  });

  test('cancels backend subscription by phone with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/by-phone/%2B255712345678/subscription/cancel',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"user":{"id":"user-1","phoneNumber":"+255712345678","role":"learner","subscriptionPlan":null,"subscriptionStartedAt":null}}',
          200,
        );
      }),
    );

    final session = await service.cancelSubscription('+255712345678');

    expect(session.phoneNumber, '+255712345678');
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
          '{"phoneNumber":"+255799000111","role":"admin","hasAdminAccess":true,"allowlistedAdmin":true,"source":"phone_allowlist"}',
          200,
        );
      }),
    );

    final diagnostics = await service.getAdminAccessDiagnostics();

    expect(diagnostics.phoneNumber, '+255799000111');
    expect(diagnostics.role, 'admin');
    expect(diagnostics.hasAdminAccess, isTrue);
    expect(diagnostics.allowlistedAdmin, isTrue);
    expect(diagnostics.source, 'phone_allowlist');
  });
}
