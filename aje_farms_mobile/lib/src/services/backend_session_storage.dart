import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The bearer token for every AJE backend request. Supabase Auth owns
/// session persistence and refresh itself (it ships its own secure storage
/// and refreshes the access token before it expires), so in production this
/// is just a thin accessor rather than a second copy of the token.
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

  @visibleForTesting
  static Future<void> writeToken(String? token) async {
    _useTestToken = true;
    _testToken = token;
  }
}
