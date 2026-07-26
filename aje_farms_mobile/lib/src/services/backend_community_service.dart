import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/community_post.dart';
import 'backend_session_storage.dart';
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
    required String content,
    required String location,
    required List<String> tags,
    String? imagePath,
  }) async {
    final payload = await _post('/api/community/posts', {
      'content': content,
      'location': location,
      'tags': tags,
      if (imagePath != null) 'imagePath': imagePath,
    });
    return _postFromJson(payload);
  }

  @override
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final headers = await _headers();
    headers['Content-Type'] = contentType;
    final response = await _client
        .post(
          _baseUrl.resolve('/api/community/posts/image'),
          headers: headers,
          body: bytes,
        )
        .timeout(timeout);

    if (response.statusCode == 501) return null;

    final payload =
        response.body.isEmpty ? const {} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommunityException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Image upload failed.',
      );
    }
    if (payload is! Map<String, dynamic> || payload['imagePath'] is! String) {
      throw const CommunityException(
          'Community service returned an invalid response.');
    }
    return payload['imagePath'] as String;
  }

  @override
  Future<CommunityReply> addReply({
    required String postId,
    required String body,
  }) async {
    final payload = await _post(
      '/api/community/posts/${Uri.encodeComponent(postId)}/replies',
      {'body': body},
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
          headers: await _headers(),
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

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await BackendSessionStorage.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
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
    imageUrl: json['imageUrl'] as String?,
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
