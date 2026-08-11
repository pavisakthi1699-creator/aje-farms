import 'dart:convert';

import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('signup requests confirmation redirect and reports pending email',
      () async {
    late http.Request capturedRequest;
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      authClient: supabase.GoTrueClient(
        url: 'https://project.supabase.co/auth/v1',
        flowType: supabase.AuthFlowType.implicit,
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'id': '4687b936-6d19-4d6e-8b2b-dbe47b5f639c',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'farmer@example.com',
              'created_at': '2026-08-02T10:00:00.000Z',
              'updated_at': '2026-08-02T10:00:00.000Z',
              'app_metadata': {'provider': 'email'},
              'user_metadata': <String, dynamic>{},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final result = await service.signUp(
      email: 'farmer@example.com',
      password: 'secret123',
    );

    expect(result.emailConfirmationRequired, isTrue);
    expect(capturedRequest.url.path, '/auth/v1/signup');
    expect(
      capturedRequest.url.queryParameters['redirect_to'],
      'https://aje-farms-api-production.up.railway.app/auth',
    );
  });

  test('resends signup confirmation to the app auth route', () async {
    late http.Request capturedRequest;
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      authClient: supabase.GoTrueClient(
        url: 'https://project.supabase.co/auth/v1',
        flowType: supabase.AuthFlowType.implicit,
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await service.resendSignUpConfirmation('farmer@example.com');

    expect(capturedRequest.url.path, '/auth/v1/resend');
    expect(
      capturedRequest.url.queryParameters['redirect_to'],
      'https://aje-farms-api-production.up.railway.app/auth',
    );
    expect(jsonDecode(capturedRequest.body)['type'], 'signup');
  });

  test('maps unconfirmed login to a recoverable typed exception', () async {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      authClient: supabase.GoTrueClient(
        url: 'https://project.supabase.co/auth/v1',
        flowType: supabase.AuthFlowType.implicit,
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'code': 'email_not_confirmed',
              'message': 'Email not confirmed',
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    expect(
      () => service.signIn(
        email: 'farmer@example.com',
        password: 'secret123',
      ),
      throwsA(isA<AuthEmailConfirmationRequiredException>()),
    );
  });

  test('explains Supabase email throttling instead of blaming the network',
      () async {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      authClient: supabase.GoTrueClient(
        url: 'https://project.supabase.co/auth/v1',
        flowType: supabase.AuthFlowType.implicit,
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'code': 'over_email_send_rate_limit',
              'message': 'email rate limit exceeded',
            }),
            429,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    expect(
      () => service.signUp(
        email: 'farmer@example.com',
        password: 'secret123',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('Barua nyingi zimetumwa'),
        ),
      ),
    );
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
      throwsA(
        isA<AuthException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });

  test('treats malformed successful auth responses as rejected sessions', () {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client:
          MockClient((_) async => http.Response('<html>broken</html>', 200)),
    );

    expect(
      () => service.getSession(),
      throwsA(isA<AuthException>()),
    );
  });

  test('separates network failures from server-rejected sessions', () {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );

    expect(
      () => service.getSession(),
      throwsA(isA<AuthNetworkException>()),
    );
  });

  test('treats a temporary backend outage as a network failure', () {
    final service = BackendAuthService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Service unavailable"}', 503);
      }),
    );

    expect(
      () => service.getSession(),
      throwsA(
        isA<AuthNetworkException>().having(
          (error) => error.statusCode,
          'statusCode',
          503,
        ),
      ),
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
