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
        _homeTopics = learningSeed.homeTopics,
        _posts = communitySeed.posts,
        _communityTopics = communitySeed.communityTopics,
        _plans = subscriptionSeed.plans;

  List<Course> _courses;
  List<AppDocument> _documents;
  List<ProblemCategory> _problemCategories;
  List<String> _homeTopics;
  List<CommunityPost> _posts;
  List<String> _communityTopics;
  List<PlanOption> _plans;
  bool _initialLoadComplete = false;
  bool _isRefreshing = false;
  bool _lastRefreshFailed = false;
  int _contentGeneration = 0;
  int _refreshGeneration = 0;

  bool get isInitialLoadPending => !_initialLoadComplete;
  bool get isRefreshing => _isRefreshing;
  bool get lastRefreshFailed => _lastRefreshFailed;
  int get contentGeneration => _contentGeneration;

  @override
  List<Course> get courses => _courses;

  @override
  List<AppDocument> get documents => _documents;

  @override
  List<ProblemCategory> get problemCategories => _problemCategories;

  @override
  List<String> get homeTopics => _homeTopics;

  void replaceHomeTopics(List<String> topics) {
    _homeTopics = List.unmodifiable(topics);
    notifyListeners();
  }

  @override
  List<CommunityPost> get posts => _posts;

  @override
  List<String> get communityTopics => _communityTopics;

  void replaceCommunityTopics(List<String> topics) {
    _communityTopics = List.unmodifiable(topics);
    notifyListeners();
  }

  @override
  List<PlanOption> get plans => _plans;

  @override
  Course? get featuredCourse => _courses.isEmpty ? null : _courses.first;

  @override
  Course? get suggestedCourse => _courses.isEmpty ? null : _courses.last;

  /// Drops account-scoped learning data before authentication changes.
  ///
  /// Community, support, and plan metadata are intentionally retained because
  /// they are not entitlement-protected. Courses and documents may contain
  /// unlocked lesson text or resource metadata, so they must never cross an
  /// account boundary.
  void clearProtectedContent() {
    _contentGeneration += 1;
    _refreshGeneration += 1;
    final stateChanged = _courses.isNotEmpty ||
        _documents.isNotEmpty ||
        _lastRefreshFailed ||
        _isRefreshing;
    _courses = const [];
    _documents = const [];
    _isRefreshing = false;
    _lastRefreshFailed = false;
    if (stateChanged) {
      notifyListeners();
    }
  }

  Future<void> refresh(CatalogService service) async {
    if (_isRefreshing) return;
    final refreshGeneration = _refreshGeneration;
    _isRefreshing = true;
    notifyListeners();
    try {
      final snapshot = await service.loadCatalog();
      if (refreshGeneration != _refreshGeneration) return;
      if (snapshot.problemCategories.isEmpty || snapshot.plans.isEmpty) {
        throw const CatalogException('Catalog response is missing core data.');
      }
      _courses = snapshot.courses;
      _documents = snapshot.documents;
      _problemCategories = snapshot.problemCategories;
      _homeTopics = snapshot.homeTopics;
      _posts = snapshot.communityPosts;
      _communityTopics = snapshot.communityTopics;
      _plans = snapshot.plans;
      _lastRefreshFailed = false;
      _contentGeneration += 1;
    } catch (_) {
      if (refreshGeneration != _refreshGeneration) return;
      _courses = const [];
      _documents = const [];
      _lastRefreshFailed = true;
      _contentGeneration += 1;
    } finally {
      if (refreshGeneration == _refreshGeneration) {
        _initialLoadComplete = true;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }
}
