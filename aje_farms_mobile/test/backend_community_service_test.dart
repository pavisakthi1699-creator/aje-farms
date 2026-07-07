import 'package:aje_farms_mobile/src/services/backend_community_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/community_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('creates a community post with backend', () async {
    await BackendSessionStorage.writeToken('token-abc');
    late http.Request capturedRequest;
    final service = BackendCommunityService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"id":"post-1","author":"Wewe","location":"Morogoro","time":"Sasa hivi","content":"Majani ya nyanya yana madoa ya njano.","likes":0,"comments":0,"tags":["Magonjwa","Nyanya"],"replies":[],"relatedTopic":"Magonjwa","hasImage":false,"isExpert":false,"isUrgent":true}',
          200,
        );
      }),
    );

    final post = await service.createPost(
      author: 'Wewe',
      content: 'Majani ya nyanya yana madoa ya njano.',
      location: 'Morogoro',
      tags: const ['Magonjwa', 'Nyanya'],
    );

    expect(post.id, 'post-1');
    expect(post.tags, ['Magonjwa', 'Nyanya']);
    expect(post.isUrgent, isTrue);
    expect(
      capturedRequest.url.toString(),
      'http://localhost:3000/api/community/posts',
    );
    expect(capturedRequest.headers['Authorization'], 'Bearer token-abc');
    expect(capturedRequest.body, contains('"location":"Morogoro"'));
  });

  test('adds a reply with backend', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendCommunityService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/community/posts/post-1/replies',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response(
          '{"author":"Wewe","body":"Angalia chini ya majani.","time":"Sasa hivi","isExpert":false}',
          200,
        );
      }),
    );

    final reply = await service.addReply(
      postId: 'post-1',
      author: 'Wewe',
      body: 'Angalia chini ya majani.',
    );

    expect(reply.body, 'Angalia chini ya majani.');
  });

  test('reports a post with backend', () async {
    await BackendSessionStorage.writeToken('token-abc');
    final service = BackendCommunityService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/community/posts/post-1/report',
        );
        expect(request.headers['Authorization'], 'Bearer token-abc');
        return http.Response('{"status":"received"}', 200);
      }),
    );

    await service.reportPost('post-1');
  });

  test('throws typed exception for backend community errors', () {
    final service = BackendCommunityService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async {
        return http.Response('{"error":"Post failed"}', 400);
      }),
    );

    expect(
      () => service.createPost(
        author: 'Wewe',
        content: 'Too short',
        location: 'Morogoro',
        tags: const ['Magonjwa'],
      ),
      throwsA(isA<CommunityException>()),
    );
  });
}
