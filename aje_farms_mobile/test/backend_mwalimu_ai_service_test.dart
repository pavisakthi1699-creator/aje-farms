import 'package:aje_farms_mobile/src/services/backend_mwalimu_ai_service.dart';
import 'package:aje_farms_mobile/src/services/mwalimu_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('calls backend chat endpoint and returns response text', () async {
    late http.Request capturedRequest;
    final service = BackendMwalimuAiService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"text":"Jibu la backend"}', 200);
      }),
    );

    final answer = await service.answer('Nisaidie kuhusu nyanya');

    expect(answer, 'Jibu la backend');
    expect(capturedRequest.url.toString(),
        'http://localhost:3000/api/mwalimu-chat');
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.body, contains('Nisaidie kuhusu nyanya'));
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

  test('fallback service returns fallback answer when primary fails', () async {
    final service = FallbackMwalimuAiService(
      primary: BackendMwalimuAiService(
        baseUrl: Uri.parse('http://localhost:3000'),
        client: MockClient((_) async {
          return http.Response('{"error":"Server failed"}', 500);
        }),
      ),
      fallback: const _StaticAiService('Jibu la akiba'),
    );

    expect(await service.answer('Swali'), 'Jibu la akiba');
  });
}

class _StaticAiService implements MwalimuAiService {
  const _StaticAiService(this.answerText);

  final String answerText;

  @override
  Future<String> answer(String prompt) async => answerText;
}
