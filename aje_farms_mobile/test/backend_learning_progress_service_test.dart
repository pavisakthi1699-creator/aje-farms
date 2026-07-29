import 'package:aje_farms_mobile/src/services/backend_learning_progress_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/learning_progress_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('loads completed lesson ids with bearer token', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendLearningProgressService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/progress',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"completedLessons":["pasheni:maandalizi-ya-shamba"],"progress":[]}',
          200,
        );
      }),
    );

    final lessons = await service.completedLessons();

    expect(lessons, {'pasheni:maandalizi-ya-shamba'});
  });

  test('marks a backend lesson complete', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendLearningProgressService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:3000/api/users/me/progress/lessons',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        expect(request.body, contains('"courseId":"pasheni"'));
        expect(request.body, contains('"lessonId":"maandalizi-ya-shamba"'));
        return http.Response(
          '{"userId":"user-1","courseId":"pasheni","lessonId":"maandalizi-ya-shamba","completedAt":"2026-07-06T10:00:00.000Z"}',
          200,
        );
      }),
    );

    await service.markLessonCompleted(
      courseId: 'pasheni',
      lessonId: 'maandalizi-ya-shamba',
    );
  });

  test('throws typed exception for backend progress errors', () {
    final service = BackendLearningProgressService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Somo halijapatikana."}', 404);
      }),
    );

    expect(
      () => service.completedLessons(),
      throwsA(isA<LearningProgressException>()),
    );
  });
}
