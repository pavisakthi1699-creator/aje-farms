import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/community_post.dart';
import 'community_service.dart';

class BackendCommunityService implements CommunityService {
  BackendCommunityService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<CommunityPost> createPost({
    required String author,
    required String content,
    required String location,
    required List<String> tags,
  }) async {
    final payload = await _post('/api/community/posts', {
      'author': author,
      'content': content,
      'location': location,
      'tags': tags,
    });
    return _postFromJson(payload);
  }

  @override
  Future<CommunityReply> addReply({
    required String postId,
    required String author,
    required String body,
  }) async {
    final payload = await _post(
      '/api/community/posts/${Uri.encodeComponent(postId)}/replies',
      {
        'author': author,
        'body': body,
      },
    );
    return _replyFromJson(payload);
  }

  @override
  Future<void> reportPost(String postId) async {
    await _post(
      '/api/community/posts/${Uri.encodeComponent(postId)}/report',
      const {},
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(
          _baseUrl.resolve(path),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final payload =
        response.body.isEmpty ? const {} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommunityException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Community request failed.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const CommunityException(
          'Community service returned an invalid response.');
    }
    return payload;
  }
}

class FallbackCommunityService implements CommunityService {
  const FallbackCommunityService({
    required this.primary,
    required this.fallback,
  });

  final CommunityService primary;
  final CommunityService fallback;

  @override
  Future<CommunityPost> createPost({
    required String author,
    required String content,
    required String location,
    required List<String> tags,
  }) async {
    try {
      return await primary.createPost(
        author: author,
        content: content,
        location: location,
        tags: tags,
      );
    } catch (_) {
      return fallback.createPost(
        author: author,
        content: content,
        location: location,
        tags: tags,
      );
    }
  }

  @override
  Future<CommunityReply> addReply({
    required String postId,
    required String author,
    required String body,
  }) async {
    try {
      return await primary.addReply(
        postId: postId,
        author: author,
        body: body,
      );
    } catch (_) {
      return fallback.addReply(
        postId: postId,
        author: author,
        body: body,
      );
    }
  }

  @override
  Future<void> reportPost(String postId) async {
    try {
      await primary.reportPost(postId);
    } catch (_) {
      await fallback.reportPost(postId);
    }
  }
}

CommunityPost _postFromJson(Map<String, dynamic> json) {
  return CommunityPost(
    id: json['id'] as String,
    author: json['author'] as String,
    location: json['location'] as String,
    time: json['time'] as String,
    content: json['content'] as String,
    likes: json['likes'] as int,
    comments: json['comments'] as int,
    tags: (json['tags'] as List<dynamic>).cast<String>(),
    replies: (json['replies'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_replyFromJson)
        .toList(),
    relatedTopic: json['relatedTopic'] as String?,
    hasImage: json['hasImage'] as bool? ?? false,
    isExpert: json['isExpert'] as bool? ?? false,
    isUrgent: json['isUrgent'] as bool? ?? false,
  );
}

CommunityReply _replyFromJson(Map<String, dynamic> json) {
  return CommunityReply(
    author: json['author'] as String,
    body: json['body'] as String,
    time: json['time'] as String,
    isExpert: json['isExpert'] as bool? ?? false,
  );
}
