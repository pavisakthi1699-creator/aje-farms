import 'package:flutter/widgets.dart';

import '../models/app_document.dart';
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
    required LearningRepository learningSeed,
    required CommunityRepository communitySeed,
    required SubscriptionRepository subscriptionSeed,
  })  : _courses = learningSeed.courses,
        _documents = learningSeed.documents,
        _problemCategories = learningSeed.problemCategories,
        _posts = communitySeed.posts,
        _plans = subscriptionSeed.plans;

  List<Course> _courses;
  List<AppDocument> _documents;
  List<ProblemCategory> _problemCategories;
  List<CommunityPost> _posts;
  List<PlanOption> _plans;
  bool _initialLoadComplete = false;
  bool _isRefreshing = false;
  bool _lastRefreshFailed = false;

  bool get isInitialLoadPending => !_initialLoadComplete;
  bool get isRefreshing => _isRefreshing;
  bool get lastRefreshFailed => _lastRefreshFailed;

  @override
  List<Course> get courses => _courses;

  @override
  List<AppDocument> get documents => _documents;

  @override
  List<ProblemCategory> get problemCategories => _problemCategories;

  @override
  List<CommunityPost> get posts => _posts;

  @override
  List<PlanOption> get plans => _plans;

  @override
  Course? get featuredCourse => _courses.isEmpty ? null : _courses.first;

  @override
  Course? get suggestedCourse => _courses.isEmpty ? null : _courses.last;

  Future<void> refresh(CatalogService service) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final snapshot = await service.loadCatalog();
      if (snapshot.problemCategories.isEmpty || snapshot.plans.isEmpty) {
        throw const CatalogException('Catalog response is missing core data.');
      }
      _courses = snapshot.courses;
      _documents = snapshot.documents;
      _problemCategories = snapshot.problemCategories;
      _posts = snapshot.communityPosts;
      _plans = snapshot.plans;
      _lastRefreshFailed = false;
    } on CatalogException {
      _lastRefreshFailed = true;
    } catch (_) {
      _lastRefreshFailed = true;
    } finally {
      _initialLoadComplete = true;
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
