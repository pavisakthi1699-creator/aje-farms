import 'dart:convert';

import 'package:aje_farms_mobile/src/models/search_result.dart';
import 'package:aje_farms_mobile/src/services/backend_search_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() => BackendSessionStorage.writeToken(null));

  test('posts an authenticated search request and parses results', () async {
    await BackendSessionStorage.writeToken('search-token');
    late http.Request captured;
    final service = BackendSearchService(
      baseUrl: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'query': 'nyanya',
            'scope': 'learning',
            'truncated': false,
            'results': [
              {
                'kind': 'course',
                'id': 'tomato',
                'title': 'Kilimo cha Nyanya',
                'metadata': 'Kozi',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await service.search(
      const SearchRequest(query: 'nyanya', scope: SearchScope.learning),
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/search');
    expect(captured.headers['authorization'], 'Bearer search-token');
    expect(jsonDecode(captured.body), {
      'query': 'nyanya',
      'scope': 'learning',
      'limit': 20,
    });
    expect(response.results.single.title, 'Kilimo cha Nyanya');
    expect(response.isOffline, isFalse);
  });

  test('surfaces authentication failures without hiding their status',
      () async {
    final service = BackendSearchService(
      baseUrl: Uri.parse('https://example.test'),
      client: MockClient(
        (_) async => http.Response('{"error":"Sign in required"}', 401),
      ),
    );

    await expectLater(
      service.search(const SearchRequest(query: 'mpunga')),
      throwsA(
        isA<SearchException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.isAuthenticationFailure, 'auth', isTrue),
      ),
    );
  });

  test('preserves authentication status for a non-JSON error body', () async {
    final service = BackendSearchService(
      baseUrl: Uri.parse('https://example.test'),
      client: MockClient(
        (_) async => http.Response('<html>Sign in</html>', 401),
      ),
    );

    await expectLater(
      service.search(const SearchRequest(query: 'mpunga')),
      throwsA(
        isA<SearchException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.isAuthenticationFailure, 'auth', isTrue),
      ),
    );
  });

  test('rejects malformed successful results as a recoverable failure',
      () async {
    final service = BackendSearchService(
      baseUrl: Uri.parse('https://example.test'),
      client: MockClient(
        (_) async => http.Response(
          '{"query":"mpunga","scope":"unknown","truncated":false,"results":[]}',
          200,
        ),
      ),
    );

    await expectLater(
      service.search(const SearchRequest(query: 'mpunga')),
      throwsA(
        isA<SearchException>().having(
          (error) => error.isRecoverableFailure,
          'recoverable',
          isTrue,
        ),
      ),
    );
  });

  test('distinguishes invalid requests from recoverable server failures', () {
    expect(
      const SearchException('invalid', statusCode: 400).isRecoverableFailure,
      isFalse,
    );
    expect(
      const SearchException('busy', statusCode: 429).isRecoverableFailure,
      isTrue,
    );
    expect(const SearchException('offline').isRecoverableFailure, isTrue);
  });

  test('parses retry guidance from a throttled response', () async {
    final service = BackendSearchService(
      baseUrl: Uri.parse('https://example.test'),
      client: MockClient(
        (_) async => http.Response(
          '{"error":"Subiri kidogo"}',
          429,
          headers: {'retry-after': '7'},
        ),
      ),
    );

    await expectLater(
      service.search(const SearchRequest(query: 'mpunga')),
      throwsA(
        isA<SearchException>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having(
              (error) => error.retryAfter,
              'retryAfter',
              const Duration(seconds: 7),
            ),
      ),
    );
  });
}
