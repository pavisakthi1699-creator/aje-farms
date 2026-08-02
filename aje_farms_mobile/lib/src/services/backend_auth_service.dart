import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_service.dart';
import 'backend_session_storage.dart';

/// Identity itself (sign up, sign in, sign out, password reset) is handled
/// entirely by Supabase Auth via the `supabase_flutter` SDK. Everything else
/// — role, account status, subscription, profile — is server-owned data read
/// from the AJE backend, authenticated with the Supabase access token (see
/// [BackendSessionStorage]).
class BackendAuthService implements AuthService {
  BackendAuthService({
    required Uri baseUrl,
    http.Client? client,
    supabase.GoTrueClient? authClient,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _authClient = authClient;

  final Uri _baseUrl;
  final http.Client _client;
  final supabase.GoTrueClient? _authClient;
  final Duration timeout;

  static const _signUpRedirectUrl = 'ajefarms://app/auth';

  supabase.GoTrueClient get _auth =>
      _authClient ?? supabase.Supabase.instance.client.auth;

  @override
  bool get hasLocalSession => _auth.currentSession != null;

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _signUpRedirectUrl,
      );
      return SignUpResult(
        emailConfirmationRequired: response.session == null,
      );
    } on supabase.AuthException catch (error) {
      throw _appAuthException(error);
    }
  }

  @override
  Future<void> resendSignUpConfirmation(String email) async {
    try {
      await _auth.resend(
        email: email,
        type: supabase.OtpType.signup,
        emailRedirectTo: _signUpRedirectUrl,
      );
    } on supabase.AuthException catch (error) {
      throw _appAuthException(error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on supabase.AuthException catch (error) {
      throw _appAuthException(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: 'ajefarms://login-callback',
      );
    } on supabase.AuthException catch (error) {
      throw _appAuthException(error);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(supabase.UserAttributes(password: newPassword));
    } on supabase.AuthException catch (error) {
      throw _appAuthException(error);
    }
  }

  @override
  Future<AuthSession> getSession() async {
    final response = await _get('/api/users/me', authenticated: true);
    return _sessionFromResponse(response);
  }

  @override
  Future<AuthSession> cancelSubscription() async {
    final response = await _post(
      '/api/users/me/subscription/cancel',
      const {},
      authenticated: true,
    );
    return _sessionFromResponse(response);
  }

  @override
  Future<AuthSession> updateProfile({
    String? displayName,
    String? preferredLocation,
  }) async {
    final response = await _post(
      '/api/users/me/profile',
      {
        if (displayName != null) 'displayName': displayName,
        if (preferredLocation != null) 'preferredLocation': preferredLocation,
      },
      authenticated: true,
    );
    return _sessionFromResponse(response);
  }

  @override
  Future<AdminAccessDiagnostics> getAdminAccessDiagnostics() async {
    final response = await _get('/api/auth/whoami', authenticated: true);
    final user = response['user'];
    return AdminAccessDiagnostics(
      email: (user is Map<String, dynamic> ? user['email'] as String? : null) ??
          '',
      role: response['role'] as String? ?? 'learner',
      hasAdminAccess: response['hasAdminAccess'] as bool? ?? false,
      allowlistedAdmin: response['allowlistedAdmin'] as bool? ?? false,
      source: response['source'] as String? ?? 'unknown',
    );
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
  if (user is! Map<String, dynamic>) {
    throw const AuthException('Auth service returned an invalid response.');
  }
  return AuthSession(
    email: user['email'] as String? ?? '',
    userId: user['id'] as String?,
    role: user['role'] as String?,
    accountStatus:
        (response['accountStatus'] ?? user['accountStatus']) as String?,
    subscriptionPlan: user['subscriptionPlan'] as String?,
    subscriptionStartedAt: _dateTimeFromJson(user['subscriptionStartedAt']),
    displayName: user['displayName'] as String?,
    preferredLocation: user['preferredLocation'] as String?,
  );
}

DateTime? _dateTimeFromJson(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

/// Supabase's own error messages are in English and sometimes overly
/// technical; translate the common ones so the auth screen reads in Swahili
/// like the rest of the app.
AuthException _appAuthException(supabase.AuthException error) {
  if (error.code == 'email_not_confirmed' ||
      error.message.toLowerCase().contains('email not confirmed')) {
    return const AuthEmailConfirmationRequiredException();
  }
  return AuthException(_friendlyAuthError(error));
}

String _friendlyAuthError(supabase.AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login credentials')) {
    return 'Barua pepe au nenosiri si sahihi.';
  }
  if (message.contains('user already registered') ||
      message.contains('already registered')) {
    return 'Akaunti ya barua pepe hii tayari ipo. Jaribu kuingia.';
  }
  if (message.contains('password should be at least')) {
    return 'Nenosiri linahitajika kuwa na angalau tarakimu 6.';
  }
  if (error.code == 'over_email_send_rate_limit' ||
      message.contains('email rate limit')) {
    return 'Barua nyingi zimetumwa kwa muda mfupi. Subiri dakika chache kisha ujaribu tena.';
  }
  if (message.contains('rate limit') || message.contains('security purposes')) {
    return 'Majaribio mengi. Subiri dakika moja kabla ya kujaribu tena.';
  }
  return error.message;
}
