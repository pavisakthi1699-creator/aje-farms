import 'package:aje_farms_mobile/src/models/community_post.dart';
import 'package:aje_farms_mobile/src/services/backend_community_service.dart';
import 'package:aje_farms_mobile/src/services/community_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('creates a community post with backend', () async {
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
    expect(capturedRequest.body, contains('"location":"Morogoro"'));
  });

  test('adds a reply with backend', () async {
    final service = BackendCommunityService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/community/posts/post-1/replies',
        );
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
    final service = BackendCommunityService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/community/posts/post-1/report',
        );
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

  test('fallback community service uses local service when backend fails',
      () async {
    final service = FallbackCommunityService(
      primary: BackendCommunityService(
        baseUrl: Uri.parse('http://localhost:3000'),
        client: MockClient((_) async {
          return http.Response('{"error":"Offline"}', 500);
        }),
      ),
      fallback: const LocalCommunityForTest(),
    );

    final post = await service.createPost(
      author: 'Wewe',
      content: 'Majani ya nyanya yana madoa ya njano.',
      location: 'Morogoro',
      tags: const ['Magonjwa'],
    );

    expect(post.id, 'local-test');
    expect(post.location, 'Morogoro');
  });
}

class LocalCommunityForTest implements CommunityService {
  const LocalCommunityForTest();

  @override
  Future<CommunityPost> createPost({
    required String author,
    required String content,
    required String location,
    required List<String> tags,
  }) async {
    return CommunityPost(
      id: 'local-test',
      author: author,
      location: location,
      time: 'Sasa hivi',
      content: content,
      likes: 0,
      comments: 0,
      tags: tags,
      replies: const [],
    );
  }

  @override
  Future<CommunityReply> addReply({
    required String postId,
    required String author,
    required String body,
  }) async {
    return CommunityReply(author: author, body: body, time: 'Sasa hivi');
  }

  @override
  Future<void> reportPost(String postId) async {}
}
