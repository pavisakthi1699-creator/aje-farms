import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'mwalimu_ai_service.dart';

class BackendMwalimuAiService implements MwalimuAiService {
  BackendMwalimuAiService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<String> answer(String prompt) async {
    final response = await _client
        .post(
          _baseUrl.resolve('/api/mwalimu-chat'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': prompt,
            'history': const [],
          }),
        )
        .timeout(timeout);

    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MwalimuAiException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Mwalimu AI request failed.',
      );
    }

    if (payload is! Map<String, dynamic> || payload['text'] is! String) {
      throw const MwalimuAiException(
          'Mwalimu AI returned an invalid response.');
    }

    return payload['text'] as String;
  }
}

class FallbackMwalimuAiService implements MwalimuAiService {
  const FallbackMwalimuAiService({
    required this.primary,
    required this.fallback,
  });

  final MwalimuAiService primary;
  final MwalimuAiService fallback;

  @override
  Future<String> answer(String prompt) async {
    try {
      return await primary.answer(prompt);
    } catch (_) {
      return fallback.answer(prompt);
    }
  }
}
