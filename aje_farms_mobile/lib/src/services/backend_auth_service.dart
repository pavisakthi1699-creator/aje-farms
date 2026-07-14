import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'backend_session_storage.dart';

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

    return _sessionFromResponse(response);
  }

  @override
  Future<AuthSession> getSession(String phoneNumber) async {
    final response = await _get(
      '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}',
      authenticated: true,
    );
    return _sessionFromResponse(response);
  }

  @override
  Future<AuthSession> cancelSubscription(String phoneNumber) async {
    final response = await _post(
      '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/subscription/cancel',
      const {},
      authenticated: true,
    );
    return _sessionFromResponse(response);
  }

  @override
  Future<AuthSession> updateProfile({
    required String phoneNumber,
    String? displayName,
    String? preferredLocation,
  }) async {
    final response = await _post(
      '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/profile',
      {
        if (displayName != null) 'displayName': displayName,
        if (preferredLocation != null) 'preferredLocation': preferredLocation,
      },
      authenticated: true,
    );
    return _sessionFromResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final response = await _client
        .post(
          _baseUrl.resolve(path),
          headers: await _headers(authenticated: authenticated),
          body: jsonEncode(body),
        )
        .timeout(timeout);

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool authenticated = false,
  }) async {
    final response = await _client
        .get(
          _baseUrl.resolve(path),
          headers: await _headers(authenticated: authenticated),
        )
        .timeout(timeout);

    return _decodeResponse(response);
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await BackendSessionStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
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

AuthSession _sessionFromResponse(Map<String, dynamic> response) {
  final user = response['user'];
  if (user is Map<String, dynamic>) {
    return AuthSession(
      phoneNumber: (response['phoneNumber'] as String?) ??
          (user['phoneNumber'] as String),
      userId: user['id'] as String?,
      role: user['role'] as String?,
      subscriptionPlan: user['subscriptionPlan'] as String?,
      subscriptionStartedAt: _dateTimeFromJson(user['subscriptionStartedAt']),
      sessionToken: response['sessionToken'] as String?,
      displayName: user['displayName'] as String?,
      preferredLocation: user['preferredLocation'] as String?,
    );
  }

  return AuthSession(
    phoneNumber: response['phoneNumber'] as String,
    sessionToken: response['sessionToken'] as String?,
  );
}

DateTime? _dateTimeFromJson(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}
