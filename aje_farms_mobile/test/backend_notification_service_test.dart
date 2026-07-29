import 'package:aje_farms_mobile/src/services/backend_notification_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('loads notification inbox with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendNotificationService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/notifications',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"settings":{"enabled":true,"communityReplies":true,"moderationUpdates":true,"learningReminders":false},"notifications":[{"id":"n-1","type":"community_reply","title":"Jibu jipya","body":"Mtaalamu amejibu.","createdAt":"2026-07-06T10:00:00.000Z","readAt":null}]}',
          200,
        );
      }),
    );

    final inbox = await service.inbox();

    expect(inbox.settings.learningReminders, isFalse);
    expect(inbox.notifications.single.title, 'Jibu jipya');
    expect(inbox.notifications.single.isRead, isFalse);
  });

  test('marks notification read', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendNotificationService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/notifications/n-1/read',
        );
        return http.Response(
          '{"notification":{"id":"n-1","type":"community_reply","title":"Jibu jipya","body":"Mtaalamu amejibu.","createdAt":"2026-07-06T10:00:00.000Z","readAt":"2026-07-06T10:01:00.000Z"}}',
          200,
        );
      }),
    );

    await service.markRead(notificationId: 'n-1');
  });

  test('registers notification device token with backend', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendNotificationService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/notifications/devices',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        expect(request.body, '{"token":"fcm-token-1","platform":"android"}');
        return http.Response(
          '{"device":{"id":"device-1","token":"fcm-token-1","platform":"android"}}',
          200,
        );
      }),
    );

    await service.registerDevice(token: 'fcm-token-1', platform: 'android');
  });

  test('throws typed exception for backend notification errors', () {
    final service = BackendNotificationService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Nope"}', 500);
      }),
    );

    expect(
      () => service.inbox(),
      throwsA(isA<NotificationException>()),
    );
  });
}
