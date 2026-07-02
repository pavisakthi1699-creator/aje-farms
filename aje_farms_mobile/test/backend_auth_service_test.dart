import 'package:aje_farms_mobile/src/services/auth_service.dart';
import 'package:aje_farms_mobile/src/services/backend_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
        return http.Response('{"phoneNumber":"+255 712345678"}', 200);
      }),
    );

    final session = await service.verifyOtp(
      phoneNumber: '+255 712345678',
      otp: '1234',
      challengeId: 'abc',
    );

    expect(session.phoneNumber, '+255 712345678');
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

  test('fallback auth service uses local auth when backend fails', () async {
    final service = FallbackAuthService(
      primary: BackendAuthService(
        baseUrl: Uri.parse('http://localhost:3000'),
        client: MockClient((_) async {
          return http.Response('{"error":"Offline"}', 500);
        }),
      ),
      fallback: const LocalAuthForTest(),
    );

    final challenge = await service.requestOtp('+255 712345678');
    final session = await service.verifyOtp(
      phoneNumber: '+255 712345678',
      otp: '0000',
      challengeId: challenge.challengeId,
    );

    expect(challenge.challengeId, 'test');
    expect(session.phoneNumber, '+255 712345678');
  });
}

class LocalAuthForTest implements AuthService {
  const LocalAuthForTest();

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    return const OtpChallenge(challengeId: 'test', message: 'fallback');
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  }) async {
    return AuthSession(phoneNumber: phoneNumber);
  }
}
