import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _secureStorage = FlutterSecureStorage(
  // A restored/invalid Android keystore key must fail to a signed-out state,
  // not prevent the app from rendering at all.
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  ),
);

String supabaseSessionStorageKey(String projectUrl) =>
    'sb-${Uri.parse(projectUrl).host.split('.').first}-auth-token';

/// Stores Supabase sessions in the platform key store and removes the legacy
/// plaintext SharedPreferences copy after an app upgrade.
class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({
    required String projectUrl,
    FlutterSecureStorage storage = _secureStorage,
  })  : _storage = storage,
        _sessionKey = supabaseSessionStorageKey(projectUrl);

  final FlutterSecureStorage _storage;
  final String _sessionKey;
  bool _available = true;

  @override
  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final secureSession = await _storage.read(key: _sessionKey);
      final legacySession = preferences.getString(_sessionKey);
      if (secureSession == null && legacySession != null) {
        await _storage.write(key: _sessionKey, value: legacySession);
      }
      if (legacySession != null) {
        await preferences.remove(_sessionKey);
      }
    } catch (_) {
      // A broken device key store must result in a signed-out session rather
      // than a white screen before runApp. Never fall back to plaintext.
      _available = false;
      await preferences.remove(_sessionKey);
    }
  }

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<String?> accessToken() async {
    if (!_available) return null;
    try {
      return await _storage.read(key: _sessionKey);
    } catch (_) {
      _available = false;
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (!_available) return;
    try {
      await _storage.write(key: _sessionKey, value: persistSessionString);
    } catch (_) {
      _available = false;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    if (!_available) return;
    try {
      await _storage.delete(key: _sessionKey);
    } catch (_) {
      _available = false;
    }
  }
}

/// Keeps PKCE verifiers out of SharedPreferences as well. A legacy verifier
/// is migrated lazily so an authentication link already in flight still works
/// across the app update.
class SecureSupabasePkceStorage extends GotrueAsyncStorage {
  const SecureSupabasePkceStorage({
    FlutterSecureStorage storage = _secureStorage,
  }) : _storage = storage;

  static const _keyPrefix = 'supabase.pkce.';
  final FlutterSecureStorage _storage;

  String _secureKey(String key) => '$_keyPrefix$key';

  @override
  Future<String?> getItem({required String key}) async {
    final secureKey = _secureKey(key);
    final secureValue = await _storage.read(key: secureKey);
    if (secureValue != null) return secureValue;

    final preferences = await SharedPreferences.getInstance();
    final legacyValue = preferences.getString(key);
    if (legacyValue == null) return null;
    await _storage.write(key: secureKey, value: legacyValue);
    await preferences.remove(key);
    return legacyValue;
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _storage.write(key: _secureKey(key), value: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _storage.delete(key: _secureKey(key));
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
