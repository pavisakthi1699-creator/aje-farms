import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/course.dart';
import '../models/plan_option.dart';
import '../models/problem_category.dart';

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.courses,
    required this.documents,
    required this.problemCategories,
    required this.communityPosts,
    required this.plans,
    required this.homeTopics,
    required this.communityTopics,
  });

  final List<Course> courses;
  final List<AppDocument> documents;
  final List<ProblemCategory> problemCategories;
  final List<CommunityPost> communityPosts;
  final List<PlanOption> plans;
  final List<String> homeTopics;
  final List<String> communityTopics;
}

abstract interface class CatalogService {
  Future<CatalogSnapshot> loadCatalog();

  /// Resolves a backend-hosted lesson video to a short-lived playable URL.
  /// Requires a signed-in session; external URLs need no resolution.
  Future<String> lessonVideoUrl(String lessonId);
}

class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}
