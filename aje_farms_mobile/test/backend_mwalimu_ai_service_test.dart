import 'package:aje_farms_mobile/src/services/backend_mwalimu_ai_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/mwalimu_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() async {
    await BackendSessionStorage.writeToken('mwalimu-test-token');
  });

  // `/api/mwalimu-chat` sits behind requireAuthSession + requirePaidLearningAccess.
  // Without this header every chat request 401s for every learner.
  test('sends the session bearer token', () async {
    late http.Request capturedRequest;
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"text":"Jibu"}', 200);
      }),
    );

    await service.answer('Swali');

    expect(
      capturedRequest.headers['Authorization'],
      'Bearer mwalimu-test-token',
    );
  });

  test('omits the Authorization header when there is no session', () async {
    await BackendSessionStorage.writeToken(null);
    late http.Request capturedRequest;
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"text":"Jibu"}', 200);
      }),
    );

    await service.answer('Swali');

    expect(capturedRequest.headers.containsKey('Authorization'), isFalse);
  });

  test('flags a 403 as needing account verification, not a network fault',
      () async {
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Ufikiaji unahitaji malipo."}', 403);
      }),
    );

    await expectLater(
      service.answer('Swali'),
      throwsA(
        isA<MwalimuAiException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.requiresVerifiedAccount, 'requiresVerified', true),
      ),
    );
  });

  test('does not flag a server error as needing verification', () async {
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Server failed"}', 500);
      }),
    );

    await expectLater(
      service.answer('Swali'),
      throwsA(
        isA<MwalimuAiException>().having(
            (e) => e.requiresVerifiedAccount, 'requiresVerified', false),
      ),
    );
  });

  test('calls backend chat endpoint and returns response text', () async {
    late http.Request capturedRequest;
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"text":"Jibu la backend","messageId":"ai-answer-1"}',
          200,
        );
      }),
    );

    final answer = await service.answer('Nisaidie kuhusu nyanya');

    expect(answer.text, 'Jibu la backend');
    expect(answer.messageId, 'ai-answer-1');
    expect(answer.sources, isEmpty);
    expect(capturedRequest.url.toString(),
        'http://localhost:3000/api/mwalimu-chat');
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.body, contains('Nisaidie kuhusu nyanya'));
  });

  test('reports a generated answer without leaving the app', () async {
    late http.Request capturedRequest;
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"status":"received"}', 200);
      }),
    );

    await service.reportAnswer('ai-answer-1', reason: 'unsafe');

    expect(
      capturedRequest.url.toString(),
      'http://localhost:3000/api/mwalimu-chat/ai-answer-1/report',
    );
    expect(
        capturedRequest.headers['Authorization'], 'Bearer mwalimu-test-token');
    expect(capturedRequest.body, contains('"reason":"unsafe"'));
  });

  test('throws typed exception for backend errors', () async {
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Server failed"}', 500);
      }),
    );

    expect(
      () => service.answer('Swali'),
      throwsA(isA<MwalimuAiException>()),
    );
  });

  test('parses grounded source cards from backend', () async {
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response(
          '{"text":"Jibu","sources":[{"id":"nyanya:udhibiti-wa-wadudu","courseId":"nyanya","lessonId":"udhibiti-wa-wadudu","courseTitle":"Kilimo cha Nyanya","title":"Udhibiti wa wadudu","type":"pdf","excerpt":"Tambua wadudu mapema."}]}',
          200,
        );
      }),
    );

    final answer = await service.answer('Nisaidie kuhusu nyanya');

    expect(answer.text, 'Jibu');
    expect(answer.sources.single.courseId, 'nyanya');
    expect(answer.sources.single.title, 'Udhibiti wa wadudu');
  });
}
