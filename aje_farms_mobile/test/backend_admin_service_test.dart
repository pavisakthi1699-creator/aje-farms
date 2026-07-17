import 'package:aje_farms_mobile/src/services/admin_service.dart';
import 'package:aje_farms_mobile/src/services/backend_admin_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('lists admin users with bearer token', () async {
    await BackendSessionStorage.writeToken('token-admin');
    late http.Request captured;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"total":1,"users":[{"id":"user-1","phoneNumber":"+255700111222","displayName":"Asha","preferredLocation":"Morogoro","role":"learner","subscriptionPlan":"Wiki 1","subscriptionStartedAt":"2026-07-01T10:00:00.000Z","createdAt":"2026-07-01T09:00:00.000Z","updatedAt":"2026-07-01T10:00:00.000Z","learningProgressCount":2,"paymentTransactionsCount":1,"notificationCount":3,"communityPostsCount":1}]}',
          200,
        );
      }),
    );

    final page = await service.listUsers(search: '255700', limit: 10, offset: 0);

    expect(page.total, 1);
    expect(page.users.single.phoneNumber, '+255700111222');
    expect(page.users.single.learningProgressCount, 2);
    expect(captured.headers['Authorization'], 'Bearer token-admin');
    expect(captured.url.queryParameters['search'], '255700');
  });

  test('throws typed exception when admin backend returns error', () async {
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async => http.Response('{"error":"Forbidden"}', 403)),
    );

    expect(
      () => service.listContentCourses(),
      throwsA(isA<AdminException>()),
    );
  });
}
