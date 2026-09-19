import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The bearer token for every AJE backend request. Supabase Auth owns
/// session persistence and refresh itself. The app configures Supabase with
/// secure local storage at startup, so this remains a thin accessor
/// rather than a second copy of the token.
///
/// Tests that don't run a real Supabase session use [writeToken] to inject a
/// fake one directly.
class BackendSessionStorage {
  static bool _useTestToken = false;
  static String? _testToken;

  static Future<String?> readToken() async {
    if (_useTestToken) return _testToken;
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  /// Stable per-account key for short-lived in-memory caches.
  ///
  /// Supabase access tokens rotate, so using the token itself as a cache key
  /// would discard safe cached data whenever the session refreshes.
  static Future<String?> readAccountCacheKey() async {
    if (_useTestToken) return _testToken;
    return Supabase.instance.client.auth.currentUser?.id;
  }

  @visibleForTesting
  static Future<void> writeToken(String? token) async {
    _useTestToken = true;
    _testToken = token;
  }
}
