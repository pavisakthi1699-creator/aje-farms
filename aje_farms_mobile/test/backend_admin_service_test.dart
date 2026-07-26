import 'dart:convert';

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

    final page =
        await service.listUsers(search: '255700', limit: 10, offset: 0);

    expect(page.total, 1);
    expect(page.users.single.phoneNumber, '+255700111222');
    expect(page.users.single.learningProgressCount, 2);
    expect(captured.headers['Authorization'], 'Bearer token-admin');
    expect(captured.url.queryParameters['search'], '255700');
  });

  test('throws typed exception when admin backend returns error', () async {
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client:
          MockClient((_) async => http.Response('{"error":"Forbidden"}', 403)),
    );

    expect(
      () => service.listContentCourses(),
      throwsA(isA<AdminException>()),
    );
  });

  test('round-trips complete curriculum fields for admin editing', () async {
    late http.Request saveRequest;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        if (request.method == 'PUT') saveRequest = request;
        return http.Response(_courseResponse, 200);
      }),
    );

    final records = await service.listContentCourses();
    final lesson = records.single.course.lessons.single;

    expect(lesson.moduleId, 'module-1');
    expect(lesson.moduleTitle, 'Mbegu');
    expect(lesson.durationMinutes, 7);
    expect(lesson.resourceUrl, 'https://video.example/rice.mp4');
    expect(lesson.isLearnerVisible, isFalse);
    expect(lesson.readinessReasons, ['Somo bado halijachapishwa.']);

    await service.upsertContentCourse(
      course: records.single.course,
      status: 'draft',
      baseUpdatedAt: records.single.updatedAt,
    );

    final sent = jsonDecode(saveRequest.body) as Map<String, dynamic>;
    expect(sent['curriculumSchemaVersion'], 2);
    expect(sent['baseUpdatedAt'], '2026-07-26T10:00:00.000Z');
    final sentLesson =
        ((sent['course'] as Map<String, dynamic>)['lessons'] as List).single
            as Map<String, dynamic>;
    expect(sentLesson['moduleId'], 'module-1');
    expect(sentLesson['moduleTitle'], 'Mbegu');
    expect(sentLesson['durationMinutes'], 7);
    expect(sentLesson['resourceUrl'], 'https://video.example/rice.mp4');
  });
}

const _courseResponse = '''
{
  "courses": [{
    "id": "RICE-SEED-001",
    "status": "draft",
    "updatedAt": "2026-07-26T10:00:00.000Z",
    "course": {
      "id": "RICE-SEED-001",
      "title": "Aina za Mbegu za Mpunga",
      "description": "Chagua mbegu sahihi.",
      "badge": "Kozi ya video",
      "icon": "play_circle",
      "progress": 0,
      "imageUrl": "assets/images/courses/mpunga.jpg",
      "outcomes": ["Mbegu"],
      "lessons": [{
        "id": "lesson-1",
        "moduleId": "module-1",
        "moduleTitle": "Mbegu",
        "title": "Utangulizi",
        "type": "video",
        "meta": "Dakika 7",
        "description": "Utangulizi wa mbegu.",
        "durationMinutes": 7,
        "resourceUrl": "https://video.example/rice.mp4",
        "readiness": {
          "visible": false,
          "reasons": ["Somo bado halijachapishwa."]
        },
        "isPremium": false,
        "isCompleted": false
      }]
    }
  }],
  "course": {
    "id": "RICE-SEED-001",
    "status": "draft",
    "updatedAt": "2026-07-26T10:00:00.000Z",
    "course": {
      "id": "RICE-SEED-001",
      "title": "Aina za Mbegu za Mpunga",
      "description": "Chagua mbegu sahihi.",
      "badge": "Kozi ya video",
      "icon": "play_circle",
      "progress": 0,
      "imageUrl": "assets/images/courses/mpunga.jpg",
      "outcomes": ["Mbegu"],
      "lessons": [{
        "id": "lesson-1",
        "moduleId": "module-1",
        "moduleTitle": "Mbegu",
        "title": "Utangulizi",
        "type": "video",
        "meta": "Dakika 7",
        "description": "Utangulizi wa mbegu.",
        "durationMinutes": 7,
        "resourceUrl": "https://video.example/rice.mp4",
        "readiness": {
          "visible": false,
          "reasons": ["Somo bado halijachapishwa."]
        },
        "isPremium": false,
        "isCompleted": false
      }]
    }
  }
}
''';
