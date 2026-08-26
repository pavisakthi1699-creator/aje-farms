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
          '{"total":1,"users":[{"id":"user-1","email":"farmer@aje.test","accountStatus":"active","displayName":"Asha","preferredLocation":"Morogoro","role":"learner","subscriptionPlan":"Wiki 1","subscriptionStartedAt":"2026-07-01T10:00:00.000Z","createdAt":"2026-07-01T09:00:00.000Z","updatedAt":"2026-07-01T10:00:00.000Z","learningProgressCount":2,"paymentTransactionsCount":1,"notificationCount":3,"communityPostsCount":1}]}',
          200,
        );
      }),
    );

    final page =
        await service.listUsers(search: 'farmer', limit: 10, offset: 0);

    expect(page.total, 1);
    expect(page.users.single.email, 'farmer@aje.test');
    expect(page.users.single.accountStatus, 'active');
    expect(page.users.single.learningProgressCount, 2);
    expect(captured.headers['Authorization'], 'Bearer token-admin');
    expect(captured.url.queryParameters['search'], 'farmer');
  });

  test('suspends learner access through the protected admin endpoint',
      () async {
    await BackendSessionStorage.writeToken('token-admin');
    late http.Request captured;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"user":{"id":"user-1","accountStatus":"suspended"},"action":"suspend"}',
          200,
        );
      }),
    );

    await service.updateUserAccess(
      userId: 'user-1',
      action: 'suspend',
      reason: 'Community safety review',
    );

    expect(captured.method, 'PUT');
    expect(captured.url.path, '/api/admin/users/user-1/access');
    expect(captured.headers['Authorization'], 'Bearer token-admin');
    expect(jsonDecode(captured.body), {
      'action': 'suspend',
      'reason': 'Community safety review',
    });
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

  test('gets and updates learner home topics with admin authorization',
      () async {
    await BackendSessionStorage.writeToken('token-admin');
    final requests = <http.Request>[];
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{"topics":["Matunda na Mbogamboga","Nafaka","Mifugo","Mengineyo"],"topicsV2":["Matunda na Mbogamboga","Nafaka","Mifugo","Mengineyo","Teknolojia"]}',
          200,
        );
      }),
    );

    final loaded = await service.getHomeTopics();
    final saved = await service.updateHomeTopics(loaded);

    expect(saved, loaded);
    expect(requests.map((request) => request.method), ['GET', 'PUT']);
    expect(requests.first.url.path, '/api/admin/settings/home-topics');
    expect(requests.last.url.path, '/api/admin/settings/home-topics-v2');
    expect(requests.last.headers['Authorization'], 'Bearer token-admin');
    expect(jsonDecode(requests.last.body), {'topics': loaded});
  });

  test('falls back to valid legacy topics when V2 topics are malformed',
      () async {
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient(
        (_) async => http.Response(
          '{"topics":["Mazao","Nafaka","Mifugo","Soko"],"topicsV2":[]}',
          200,
        ),
      ),
    );

    expect(
      await service.getHomeTopics(),
      const ['Mazao', 'Nafaka', 'Mifugo', 'Soko'],
    );
  });

  test('gets and updates community topics', () async {
    await BackendSessionStorage.writeToken('token-admin');
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          expect(request.url.path, '/api/admin/settings/community-topics');
          expect(
            jsonDecode(request.body),
            {
              'topics': ['Mifugo', 'Matunda', 'Teknolojia'],
            },
          );
        }
        return http.Response(
          '{"topics":["Mifugo","Matunda","Teknolojia"]}',
          200,
        );
      }),
    );

    expect(await service.getCommunityTopics(),
        ['Mifugo', 'Matunda', 'Teknolojia']);
    expect(
      await service.updateCommunityTopics(
        const ['Mifugo', 'Matunda', 'Teknolojia'],
      ),
      ['Mifugo', 'Matunda', 'Teknolojia'],
    );
  });

  test('fails safely when the V2 topic endpoint is unavailable', () async {
    late http.Request captured;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient(
        (request) async {
          captured = request;
          return http.Response('{"error":"Not found"}', 404);
        },
      ),
    );

    await expectLater(
      service.updateHomeTopics(
        const ['Mazao', 'Nafaka', 'Mifugo', 'Soko', 'Teknolojia'],
      ),
      throwsA(isA<AdminException>()),
    );
    expect(captured.url.path, '/api/admin/settings/home-topics-v2');
    expect(
      jsonDecode(captured.body),
      {
        'topics': ['Mazao', 'Nafaka', 'Mifugo', 'Soko', 'Teknolojia'],
      },
    );
  });

  test('rejects a malformed home-topic response', () async {
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient(
        (_) async => http.Response('{"topics":["Moja",12,"Tatu","Nne"]}', 200),
      ),
    );

    expect(service.getHomeTopics(), throwsA(isA<AdminException>()));
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

  test('deletes a course through the protected admin endpoint', () async {
    await BackendSessionStorage.writeToken('token-admin');
    late http.Request captured;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"deleted":true,"courseId":"CRS-001"}', 200);
      }),
    );

    await service.deleteContentCourse('CRS-001');

    expect(captured.method, 'DELETE');
    expect(captured.url.path, '/api/admin/content/courses/CRS-001');
    expect(captured.headers['Authorization'], 'Bearer token-admin');
  });

  test('streams preview media to the signed Storage URL', () async {
    final methods = <String>[];
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        methods.add(request.method);
        if (request.url.path == '/api/admin/content/media/upload-url') {
          return http.Response(
            '{"uploadUrl":"https://storage.test/upload",'
            '"publicUrl":"https://storage.test/public/cover.jpg"}',
            200,
          );
        }
        return http.Response('', 200);
      }),
    );

    final result = await service.uploadContentMedia(
      stream: Stream.value(utf8.encode('image-bytes')),
      contentLength: utf8.encode('image-bytes').length,
      contentType: 'image/jpeg',
      kind: 'image',
    );

    expect(result, 'https://storage.test/public/cover.jpg');
    expect(methods, ['POST', 'PUT']);
  });

  test('turns preview upload network failures into AdminException', () async {
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        if (request.url.path == '/api/admin/content/media/upload-url') {
          return http.Response(
            '{"uploadUrl":"https://storage.test/upload",'
            '"publicUrl":"https://storage.test/public/cover.jpg"}',
            200,
          );
        }
        throw http.ClientException('offline');
      }),
    );

    await expectLater(
      service.uploadContentMedia(
        stream: Stream.value(utf8.encode('image-bytes')),
        contentLength: utf8.encode('image-bytes').length,
        contentType: 'image/jpeg',
        kind: 'image',
      ),
      throwsA(isA<AdminException>()),
    );
  });

  test('searches approved source segments with bearer token', () async {
    await BackendSessionStorage.writeToken('token-admin');
    late http.Request captured;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"segments":[{"id":"segment-1","documentId":"document-1",'
          '"documentTitle":"Mwongozo wa Maharage",'
          '"sectionTitle":"Maandalizi","locationLabel":"Kurasa 10-12",'
          '"contentPreview":"Chagua eneo lenye mifereji."}]}',
          200,
        );
      }),
    );

    final segments = await service.searchSourceSegments(search: 'maharage');

    expect(segments.single.id, 'segment-1');
    expect(segments.single.documentTitle, 'Mwongozo wa Maharage');
    expect(captured.method, 'GET');
    expect(captured.headers['Authorization'], 'Bearer token-admin');
    expect(captured.url.queryParameters['search'], 'maharage');
  });

  test('submits lesson source review evidence', () async {
    await BackendSessionStorage.writeToken('token-admin');
    late http.Request captured;
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"status":"approved","contentReady":true,'
          '"courseUpdatedAt":"2026-07-26T12:30:00.000Z"}',
          200,
        );
      }),
    );

    final review = await service.approveLessonSource(
      lessonId: 'lesson/1',
      sourceSegmentId: 'segment-1',
      evidenceNote: 'Sehemu hii inaunga mkono somo.',
      groundingFact: 'Udongo unaopitisha maji hupunguza kutuama.',
    );

    expect(captured.method, 'POST');
    expect(
      captured.url.path,
      '/api/admin/content/lessons/lesson%2F1/source-review',
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['sourceSegmentId'], 'segment-1');
    expect(body['evidenceNote'], 'Sehemu hii inaunga mkono somo.');
    expect(
      body['groundingFact'],
      'Udongo unaopitisha maji hupunguza kutuama.',
    );
    expect(review.contentReady, isTrue);
    expect(
      review.courseUpdatedAt,
      DateTime.parse('2026-07-26T12:30:00.000Z'),
    );
  });

  test('loads and resolves AI and account-deletion moderation queues',
      () async {
    await BackendSessionStorage.writeToken('token-admin');
    final requests = <http.Request>[];
    final service = BackendAdminService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/ai-reports') &&
            request.method == 'GET') {
          return http.Response(
            '{"reports":[{"report":{"id":"ai-report-1","reason":"inaccurate","details":"Si sahihi","reportedAt":"2026-08-11T10:00:00.000Z"},"answer":{"prompt":"Nifanye nini?","answer":"Jibu la AI"}}]}',
            200,
          );
        }
        if (request.url.path.endsWith('/account-deletion-requests') &&
            request.method == 'GET') {
          return http.Response(
            '{"requests":[{"id":"deletion-1","email":"farmer@aje.test","status":"pending","requestedAt":"2026-08-11T11:00:00.000Z"}]}',
            200,
          );
        }
        return http.Response('{"status":"ok"}', 200);
      }),
    );

    final aiReports = await service.listAiReports();
    final deletionRequests = await service.listAccountDeletionRequests();
    await service.resolveAiReport(aiReports.single.id);
    await service.resolveAccountDeletionRequest(
      requestId: deletionRequests.single.id,
      status: 'completed',
    );

    expect(aiReports.single.reason, 'inaccurate');
    expect(deletionRequests.single.email, 'farmer@aje.test');
    expect(requests.map((request) => request.method),
        ['GET', 'GET', 'PUT', 'PUT']);
    expect(
      requests.every(
        (request) => request.headers['Authorization'] == 'Bearer token-admin',
      ),
      isTrue,
    );
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
