import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_session_storage.dart';
import 'learning_progress_service.dart';

class BackendLearningProgressService implements LearningProgressService {
  BackendLearningProgressService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<Set<String>> completedLessons(String phoneNumber) async {
    final response = await _client
        .get(
          _baseUrl.resolve(
            '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/progress',
          ),
          headers: await _headers(),
        )
        .timeout(timeout);
    final payload = _decodeResponse(response);
    return (payload['completedLessons'] as List<dynamic>)
        .cast<String>()
        .toSet();
  }

  @override
  Future<void> markLessonCompleted({
    required String phoneNumber,
    required String courseId,
    required String lessonId,
  }) async {
    final response = await _client
        .post(
          _baseUrl.resolve(
            '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/progress/lessons',
          ),
          headers: await _headers(),
          body: jsonEncode({
            'courseId': courseId,
            'lessonId': lessonId,
          }),
        )
        .timeout(timeout);
    _decodeResponse(response);
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await BackendSessionStorage.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LearningProgressException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Learning progress request failed.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const LearningProgressException(
        'Learning progress service returned an invalid response.',
      );
    }
    return payload;
  }
}
