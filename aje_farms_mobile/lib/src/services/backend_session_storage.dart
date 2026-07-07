import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BackendSessionStorage {
  static const sessionTokenKey = 'app_session.session_token';
  static const _storage = FlutterSecureStorage();

  static Future<String?> readToken() async {
    return _storage.read(key: sessionTokenKey);
  }

  static Future<void> writeToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: sessionTokenKey);
      return;
    }
    await _storage.write(key: sessionTokenKey, value: token);
  }
}
