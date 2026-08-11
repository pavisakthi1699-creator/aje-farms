import 'package:aje_farms_mobile/src/services/secure_supabase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const projectUrl = 'https://project-ref.supabase.co';
  final sessionKey = supabaseSessionStorageKey(projectUrl);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('migrates the legacy Supabase session and removes its plaintext copy',
      () async {
    SharedPreferences.setMockInitialValues({sessionKey: 'legacy-session'});
    final storage = SecureSupabaseLocalStorage(projectUrl: projectUrl);

    await storage.initialize();

    expect(await storage.accessToken(), 'legacy-session');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(sessionKey), isFalse);
  });

  test('persists and removes sessions using secure storage', () async {
    final storage = SecureSupabaseLocalStorage(projectUrl: projectUrl);
    await storage.initialize();

    await storage.persistSession('new-session');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'new-session');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('a broken device key store starts safely in a signed-out state',
      () async {
    SharedPreferences.setMockInitialValues({sessionKey: 'plaintext-session'});
    final storage = SecureSupabaseLocalStorage(
      projectUrl: projectUrl,
      storage: const _ThrowingSecureStorage(),
    );

    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(sessionKey), isFalse);
  });

  test('migrates an in-flight PKCE verifier before returning it', () async {
    SharedPreferences.setMockInitialValues({'pkce.code-verifier': 'verifier'});
    const storage = SecureSupabasePkceStorage();

    expect(
      await storage.getItem(key: 'pkce.code-verifier'),
      'verifier',
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('pkce.code-verifier'), isFalse);

    await storage.removeItem(key: 'pkce.code-verifier');
    expect(await storage.getItem(key: 'pkce.code-verifier'), isNull);
  });
}

class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('Device key store is unavailable.');
  }
}
