import '../models/community_post.dart';

/// Authorship is derived from the session by the backend, so callers do not
/// supply an author. See `communityDisplayName` in `server/store/utils.js`.
abstract class CommunityService {
  Future<CommunityPost> createPost({
    required String content,
    required String location,
    required List<String> tags,
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
