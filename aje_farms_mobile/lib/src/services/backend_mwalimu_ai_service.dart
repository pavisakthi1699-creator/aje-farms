import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_session_storage.dart';
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
    // `/api/mwalimu-chat` requires a session and an active entitlement, so the
    // bearer token is mandatory here — without it every request 401s.
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await BackendSessionStorage.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _client
        .post(
          _baseUrl.resolve('/api/mwalimu-chat'),
          headers: headers,
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
        statusCode: response.statusCode,
      );
    }

    if (payload is! Map<String, dynamic> || payload['text'] is! String) {
      throw const MwalimuAiException(
          'Mwalimu AI returned an invalid response.');
    }

    return MwalimuAiAnswer(
      text: payload['text'] as String,
      messageId: payload['messageId'] as String?,
      sources: (payload['sources'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(_sourceFromJson)
          .toList(),
    );
  }

  @override
  Future<void> reportAnswer(
    String messageId, {
    required String reason,
    String? details,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await BackendSessionStorage.readToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await _client
        .post(
          _baseUrl.resolve(
            '/api/mwalimu-chat/${Uri.encodeComponent(messageId)}/report',
          ),
          headers: headers,
          body: jsonEncode({
            'reason': reason,
            if (details != null) 'details': details,
          }),
        )
        .timeout(timeout);
    final payload =
        response.body.isEmpty ? const {} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MwalimuAiException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Imeshindikana kutuma ripoti ya AI.',
        statusCode: response.statusCode,
      );
    }
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
