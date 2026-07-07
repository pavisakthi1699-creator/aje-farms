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
  });

  final List<Course> courses;
  final List<AppDocument> documents;
  final List<ProblemCategory> problemCategories;
  final List<CommunityPost> communityPosts;
  final List<PlanOption> plans;
}

abstract interface class CatalogService {
  Future<CatalogSnapshot> loadCatalog();
}

class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}
