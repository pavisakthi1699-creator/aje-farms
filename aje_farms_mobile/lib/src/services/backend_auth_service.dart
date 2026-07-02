import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class BackendAuthService implements AuthService {
  BackendAuthService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    final response = await _post('/api/auth/request-otp', {
      'phoneNumber': phoneNumber,
    });

    return OtpChallenge(
      challengeId: response['challengeId'] as String,
      message: response['message'] as String,
      debugOtp: response['debugOtp'] as String?,
    );
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  }) async {
    final response = await _post('/api/auth/verify-otp', {
      'phoneNumber': phoneNumber,
      'otp': otp,
      'challengeId': challengeId,
    });

    return AuthSession(phoneNumber: response['phoneNumber'] as String);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(
          _baseUrl.resolve(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Auth request failed.',
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw const AuthException('Auth service returned an invalid response.');
    }
    return payload;
  }
}

class FallbackAuthService implements AuthService {
  const FallbackAuthService({
    required this.primary,
    required this.fallback,
  });

  final AuthService primary;
  final AuthService fallback;

  @override
  Future<OtpChallenge> requestOtp(String phoneNumber) async {
    try {
      return await primary.requestOtp(phoneNumber);
    } catch (_) {
      return fallback.requestOtp(phoneNumber);
    }
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otp,
    required String challengeId,
  }) async {
    try {
      return await primary.verifyOtp(
        phoneNumber: phoneNumber,
        otp: otp,
        challengeId: challengeId,
      );
    } catch (_) {
      return fallback.verifyOtp(
        phoneNumber: phoneNumber,
        otp: otp,
        challengeId: challengeId,
      );
    }
  }
}
