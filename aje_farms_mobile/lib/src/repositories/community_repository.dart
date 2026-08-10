import '../models/community_post.dart';

abstract interface class CommunityRepository {
  List<CommunityPost> get posts;
  List<String> get communityTopics;
}
