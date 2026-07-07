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
  Future<MwalimuAiAnswer> answer(String prompt) async {
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

    return MwalimuAiAnswer(
      text: payload['text'] as String,
      sources: (payload['sources'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_sourceFromJson)
          .toList(),
    );
  }
}

MwalimuAiSource _sourceFromJson(Map<String, dynamic> json) {
  return MwalimuAiSource(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    lessonId: json['lessonId'] as String,
    courseTitle: json['courseTitle'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    excerpt: json['excerpt'] as String,
  );
}
