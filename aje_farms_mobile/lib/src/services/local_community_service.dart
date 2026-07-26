import 'dart:typed_data';

import '../models/community_post.dart';
import 'community_service.dart';

class LocalCommunityService implements CommunityService {
  const LocalCommunityService();

  @override
  Future<CommunityPost> createPost({
    required String content,
    required String location,
    required List<String> tags,
    String? imagePath,
  }) async {
    return CommunityPost(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      author: 'Mkulima',
      location: location,
      time: 'Sasa hivi',
      content: content,
      likes: 0,
      comments: 0,
      tags: tags,
      replies: const [],
      hasImage: imagePath != null,
      isUrgent: tags.contains('Magonjwa') || tags.contains('Wadudu'),
    );
  }

  @override
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String contentType,
  }) async {
    // The demo/offline backend has no storage to upload to.
    return null;
  }

  @override
  Future<CommunityReply> addReply({
    required String postId,
    required String body,
  }) async {
    return CommunityReply(
      author: 'Mkulima',
      body: body,
      time: 'Sasa hivi',
    );
  }

  @override
  Future<void> reportPost(String postId) async {}
}
