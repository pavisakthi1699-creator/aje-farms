import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_session_storage.dart';
import 'notification_service.dart';

class BackendNotificationService implements NotificationService {
  BackendNotificationService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<NotificationInbox> inbox(String phoneNumber) async {
    final response = await _client
        .get(
          _baseUrl.resolve(
            '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/notifications',
          ),
          headers: await _headers(),
        )
        .timeout(timeout);
    final payload = _decodeResponse(response);
    return NotificationInbox(
      settings: _settingsFromJson(payload['settings'] as Map<String, dynamic>),
      notifications: (payload['notifications'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_notificationFromJson)
          .toList(),
    );
  }

  @override
  Future<void> markRead({
    required String phoneNumber,
    required String notificationId,
  }) async {
    final response = await _client
        .post(
          _baseUrl.resolve(
            '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/notifications/${Uri.encodeComponent(notificationId)}/read',
          ),
          headers: await _headers(),
          body: '{}',
        )
        .timeout(timeout);
    _decodeResponse(response);
  }

  @override
  Future<NotificationSettings> updateSettings({
    required String phoneNumber,
    required bool enabled,
  }) async {
    final response = await _client
        .put(
          _baseUrl.resolve(
            '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/notifications/settings',
          ),
          headers: await _headers(),
          body: jsonEncode({'enabled': enabled}),
        )
        .timeout(timeout);
    final payload = _decodeResponse(response);
    return _settingsFromJson(payload['settings'] as Map<String, dynamic>);
  }

  @override
  Future<void> registerDevice({
    required String phoneNumber,
    required String token,
    required String platform,
  }) async {
    final response = await _client
        .post(
          _baseUrl.resolve(
            '/api/users/by-phone/${Uri.encodeComponent(phoneNumber)}/notifications/devices',
          ),
          headers: await _headers(),
          body: jsonEncode({
            'token': token,
            'platform': platform,
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
      throw NotificationException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Notification request failed.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const NotificationException(
        'Notification service returned an invalid response.',
      );
    }
    return payload;
  }
}

NotificationSettings _settingsFromJson(Map<String, dynamic> json) {
  return NotificationSettings(
    enabled: json['enabled'] as bool? ?? true,
    communityReplies: json['communityReplies'] as bool? ?? true,
    moderationUpdates: json['moderationUpdates'] as bool? ?? true,
    learningReminders: json['learningReminders'] as bool? ?? true,
  );
}

AppNotification _notificationFromJson(Map<String, dynamic> json) {
  return AppNotification(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    readAt: json['readAt'] is String
        ? DateTime.tryParse(json['readAt'] as String)
        : null,
  );
}
