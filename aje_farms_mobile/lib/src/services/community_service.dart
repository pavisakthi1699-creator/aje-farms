import '../models/community_post.dart';

abstract class CommunityService {
  Future<CommunityPost> createPost({
    required String author,
    required String content,
    required String location,
    required List<String> tags,
  });

  Future<CommunityReply> addReply({
    required String postId,
    required String author,
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
