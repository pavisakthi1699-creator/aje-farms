import 'package:flutter/widgets.dart';

import '../models/community_post.dart';
import '../models/course.dart';
import '../models/plan_option.dart';
import '../models/problem_category.dart';
import '../services/catalog_service.dart';
import 'community_repository.dart';
import 'learning_repository.dart';
import 'subscription_repository.dart';

class CachedAppRepository extends ChangeNotifier
    implements LearningRepository, CommunityRepository, SubscriptionRepository {
  CachedAppRepository({
    required LearningRepository learningFallback,
    required CommunityRepository communityFallback,
    required SubscriptionRepository subscriptionFallback,
  })  : _courses = learningFallback.courses,
        _problemCategories = learningFallback.problemCategories,
        _posts = communityFallback.posts,
        _plans = subscriptionFallback.plans;

  List<Course> _courses;
  List<ProblemCategory> _problemCategories;
  List<CommunityPost> _posts;
  List<PlanOption> _plans;

  @override
  List<Course> get courses => _courses;

  @override
  List<ProblemCategory> get problemCategories => _problemCategories;

  @override
  List<CommunityPost> get posts => _posts;

  @override
  List<PlanOption> get plans => _plans;

  @override
  Course get featuredCourse => _courses.first;

  @override
  Course get suggestedCourse => _courses.last;

  Future<void> refresh(CatalogService service) async {
    final snapshot = await service.loadCatalog();
    if (snapshot.courses.isEmpty ||
        snapshot.problemCategories.isEmpty ||
        snapshot.plans.isEmpty) {
      throw const CatalogException('Catalog response is missing core data.');
    }
    _courses = snapshot.courses;
    _problemCategories = snapshot.problemCategories;
    _posts = snapshot.communityPosts;
    _plans = snapshot.plans;
    notifyListeners();
  }
}
