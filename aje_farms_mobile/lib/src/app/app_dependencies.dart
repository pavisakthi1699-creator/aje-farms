import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/course.dart';
import '../models/plan_option.dart';
import '../models/problem_category.dart';
import '../repositories/cached_app_repository.dart';
import '../repositories/community_repository.dart';
import '../repositories/demo_app_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/subscription_repository.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/backend_admin_service.dart';
import '../services/backend_auth_service.dart';
import '../services/backend_catalog_service.dart';
import '../services/backend_community_service.dart';
import '../services/backend_learning_progress_service.dart';
import '../services/backend_mwalimu_ai_service.dart';
import '../services/backend_notification_service.dart';
import '../services/backend_payment_service.dart';
import '../services/backend_search_service.dart';
import '../services/community_service.dart';
import '../services/demo_mwalimu_ai_service.dart';
import '../services/catalog_service.dart';
import '../services/local_auth_service.dart';
import '../services/local_catalog_service.dart';
import '../services/local_admin_service.dart';
import '../services/local_community_service.dart';
import '../services/local_learning_progress_service.dart';
import '../services/local_notification_service.dart';
import '../services/local_payment_service.dart';
import '../services/local_search_service.dart';
import '../services/learning_progress_service.dart';
import '../services/mwalimu_ai_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../services/search_service.dart';

class AppDependencies {
  const AppDependencies({
    required this.learningRepository,
    required this.communityRepository,
    required this.subscriptionRepository,
    required this.mwalimuAiService,
    required this.authService,
    required this.catalogService,
    required this.adminService,
    required this.communityService,
    required this.learningProgressService,
    required this.notificationService,
    required this.paymentService,
    required this.searchService,
    required this.offlineSearchService,
    required this.refreshCatalog,
    this.refreshListenable,
  });

  AppDependencies copyWith({
    AdminService? adminService,
    AuthService? authService,
    CommunityService? communityService,
    CommunityRepository? communityRepository,
    MwalimuAiService? mwalimuAiService,
    SearchService? searchService,
    SearchService? offlineSearchService,
    Future<void> Function()? refreshCatalog,
  }) {
    return AppDependencies(
      learningRepository: learningRepository,
      communityRepository: communityRepository ?? this.communityRepository,
      subscriptionRepository: subscriptionRepository,
      mwalimuAiService: mwalimuAiService ?? this.mwalimuAiService,
      authService: authService ?? this.authService,
      catalogService: catalogService,
      adminService: adminService ?? this.adminService,
      communityService: communityService ?? this.communityService,
      learningProgressService: learningProgressService,
      notificationService: notificationService,
      paymentService: paymentService,
      searchService: searchService ?? this.searchService,
      offlineSearchService: offlineSearchService ?? this.offlineSearchService,
      refreshCatalog: refreshCatalog ?? this.refreshCatalog,
      refreshListenable: refreshListenable,
    );
  }

  factory AppDependencies.demo() {
    const repository = DemoAppRepository();
    return const AppDependencies(
      learningRepository: repository,
      communityRepository: repository,
      subscriptionRepository: repository,
      mwalimuAiService: DemoMwalimuAiService(),
      authService: LocalAuthService(),
      catalogService: LocalCatalogService(),
      adminService: LocalAdminService(),
      communityService: LocalCommunityService(),
      learningProgressService: LocalLearningProgressService(),
      notificationService: LocalNotificationService(),
      paymentService: LocalPaymentService(),
      searchService: LocalSearchService(
        learningRepository: repository,
        communityRepository: repository,
      ),
      offlineSearchService: LocalSearchService(
        learningRepository: repository,
        communityRepository: repository,
      ),
      refreshCatalog: _demoRefreshCatalog,
    );
  }

  static Future<void> _demoRefreshCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  factory AppDependencies.production({Uri? baseUrl}) {
    const emptyLearningRepository = _EmptyLearningRepository();
    const emptyCommunityRepository = _EmptyCommunityRepository();
    const emptySubscriptionRepository = _EmptySubscriptionRepository();
    final apiBaseUrl = baseUrl ?? Uri.tryParse(_apiBaseUrl);
    final hasBackend = apiBaseUrl != null &&
        apiBaseUrl.hasScheme &&
        apiBaseUrl.host.isNotEmpty;
    if (!hasBackend) {
      throw StateError(
        'AJE_API_BASE_URL must be provided for the connected Android app.',
      );
    }
    late final LearningRepository learningRepository;
    late final CommunityRepository communityRepository;
    late final SubscriptionRepository subscriptionRepository;
    Listenable? refreshListenable;
    final cachedRepository = CachedAppRepository(
      learningSeed: emptyLearningRepository,
      communitySeed: emptyCommunityRepository,
      subscriptionSeed: emptySubscriptionRepository,
    );
    learningRepository = cachedRepository;
    communityRepository = cachedRepository;
    subscriptionRepository = cachedRepository;
    final catalogService = BackendCatalogService(baseUrl: apiBaseUrl);
    refreshListenable = cachedRepository;
    return AppDependencies(
      learningRepository: learningRepository,
      communityRepository: communityRepository,
      subscriptionRepository: subscriptionRepository,
      mwalimuAiService: BackendMwalimuAiService(baseUrl: apiBaseUrl),
      authService: BackendAuthService(baseUrl: apiBaseUrl),
      catalogService: catalogService,
      adminService: BackendAdminService(baseUrl: apiBaseUrl),
      communityService: BackendCommunityService(baseUrl: apiBaseUrl),
      learningProgressService: BackendLearningProgressService(
        baseUrl: apiBaseUrl,
      ),
      notificationService: BackendNotificationService(baseUrl: apiBaseUrl),
      paymentService: BackendPaymentService(baseUrl: apiBaseUrl),
      searchService: BackendSearchService(baseUrl: apiBaseUrl),
      offlineSearchService: LocalSearchService(
        learningRepository: learningRepository,
        communityRepository: communityRepository,
      ),
      refreshListenable: refreshListenable,
      refreshCatalog: () => cachedRepository.refresh(catalogService),
    );
  }

  final LearningRepository learningRepository;
  final CommunityRepository communityRepository;
  final SubscriptionRepository subscriptionRepository;
  final MwalimuAiService mwalimuAiService;
  final AuthService authService;
  final CatalogService catalogService;
  final AdminService adminService;
  final CommunityService communityService;
  final LearningProgressService learningProgressService;
  final NotificationService notificationService;
  final PaymentService paymentService;
  final SearchService searchService;
  final SearchService offlineSearchService;
  final Future<void> Function() refreshCatalog;
  final Listenable? refreshListenable;

  CachedAppRepository? get cachedRepository =>
      refreshListenable is CachedAppRepository
          ? refreshListenable! as CachedAppRepository
          : null;
}

const _apiBaseUrl = String.fromEnvironment('AJE_API_BASE_URL',
    defaultValue: String.fromEnvironment('MWALIMU_API_BASE_URL'));

class _EmptyLearningRepository implements LearningRepository {
  const _EmptyLearningRepository();

  @override
  List<Course> get courses => const [];

  @override
  List<AppDocument> get documents => const [];

  @override
  List<ProblemCategory> get problemCategories => const [];

  @override
  List<String> get homeTopics => const [];

  @override
  Course? get featuredCourse => null;

  @override
  Course? get suggestedCourse => null;
}

class _EmptyCommunityRepository implements CommunityRepository {
  const _EmptyCommunityRepository();

  @override
  List<CommunityPost> get posts => const [];

  @override
  List<String> get communityTopics => const [];
}

class _EmptySubscriptionRepository implements SubscriptionRepository {
  const _EmptySubscriptionRepository();

  @override
  List<PlanOption> get plans => const [];
}

class AppDependenciesScope extends InheritedNotifier<Listenable> {
  AppDependenciesScope({
    required this.dependencies,
    required super.child,
    super.key,
  }) : super(notifier: dependencies.refreshListenable);

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'AppDependenciesScope was not found in the tree.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) =>
      dependencies != oldWidget.dependencies ||
      super.updateShouldNotify(oldWidget);
}

extension AppDependenciesContext on BuildContext {
  AppDependencies get dependencies => AppDependenciesScope.of(this);
}
