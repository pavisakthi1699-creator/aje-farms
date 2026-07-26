import 'dart:typed_data';

import '../models/community_post.dart';

/// Authorship is derived from the session by the backend, so callers do not
/// supply an author. See `communityDisplayName` in `server/store/utils.js`.
abstract class CommunityService {
  Future<CommunityPost> createPost({
    required String content,
    required String location,
    required List<String> tags,
    String? imagePath,
  });

  /// Uploads image bytes and returns the storage path to pass to
  /// [createPost]. Returns null when image uploads are not available (e.g.
  /// local/dev backends without Supabase Storage configured).
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String contentType,
  });

  Future<CommunityReply> addReply({
    required String postId,
    required String body,
  });

  Future<void> reportPost(String postId);
}

class CommunityException implements Exception {
  const CommunityException(this.message);

  final String message;

  @override
  String toString() => message;
}
