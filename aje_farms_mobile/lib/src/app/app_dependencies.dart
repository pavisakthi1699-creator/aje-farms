import 'dart:async';

import 'package:flutter/widgets.dart';

import '../repositories/cached_app_repository.dart';
import '../repositories/community_repository.dart';
import '../repositories/demo_app_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/subscription_repository.dart';
import '../services/auth_service.dart';
import '../services/backend_auth_service.dart';
import '../services/backend_catalog_service.dart';
import '../services/backend_community_service.dart';
import '../services/backend_mwalimu_ai_service.dart';
import '../services/backend_payment_service.dart';
import '../services/community_service.dart';
import '../services/demo_mwalimu_ai_service.dart';
import '../services/local_auth_service.dart';
import '../services/local_community_service.dart';
import '../services/local_payment_service.dart';
import '../services/mwalimu_ai_service.dart';
import '../services/payment_service.dart';

class AppDependencies {
  const AppDependencies({
    required this.learningRepository,
    required this.communityRepository,
    required this.subscriptionRepository,
    required this.mwalimuAiService,
    required this.authService,
    required this.communityService,
    required this.paymentService,
    this.refreshListenable,
  });

  factory AppDependencies.demo() {
    const repository = DemoAppRepository();
    return const AppDependencies(
      learningRepository: repository,
      communityRepository: repository,
      subscriptionRepository: repository,
      mwalimuAiService: DemoMwalimuAiService(),
      authService: LocalAuthService(),
      communityService: LocalCommunityService(),
      paymentService: LocalPaymentService(),
    );
  }

  factory AppDependencies.localFirst() {
    const fallbackRepository = DemoAppRepository();
    const fallbackAiService = DemoMwalimuAiService();
    const fallbackAuthService = LocalAuthService();
    const fallbackCommunityService = LocalCommunityService();
    const fallbackPaymentService = LocalPaymentService();
    final apiBaseUrl = Uri.tryParse(_apiBaseUrl);
    final hasBackend = apiBaseUrl != null &&
        apiBaseUrl.hasScheme &&
        apiBaseUrl.host.isNotEmpty;
    late final LearningRepository learningRepository;
    late final CommunityRepository communityRepository;
    late final SubscriptionRepository subscriptionRepository;
    Listenable? refreshListenable;
    if (hasBackend) {
      final cachedRepository = CachedAppRepository(
        learningFallback: fallbackRepository,
        communityFallback: fallbackRepository,
        subscriptionFallback: fallbackRepository,
      );
      learningRepository = cachedRepository;
      communityRepository = cachedRepository;
      subscriptionRepository = cachedRepository;
      refreshListenable = cachedRepository;
      unawaited(cachedRepository
          .refresh(BackendCatalogService(baseUrl: apiBaseUrl))
          .catchError((_) {}));
    } else {
      learningRepository = fallbackRepository;
      communityRepository = fallbackRepository;
      subscriptionRepository = fallbackRepository;
    }
    final aiService = !hasBackend
        ? fallbackAiService
        : FallbackMwalimuAiService(
            primary: BackendMwalimuAiService(baseUrl: apiBaseUrl),
            fallback: fallbackAiService,
          );
    final authService = !hasBackend
        ? fallbackAuthService
        : FallbackAuthService(
            primary: BackendAuthService(baseUrl: apiBaseUrl),
            fallback: fallbackAuthService,
          );
    final paymentService = !hasBackend
        ? fallbackPaymentService
        : FallbackPaymentService(
            primary: BackendPaymentService(baseUrl: apiBaseUrl),
            fallback: fallbackPaymentService,
          );
    final communityService = !hasBackend
        ? fallbackCommunityService
        : FallbackCommunityService(
            primary: BackendCommunityService(baseUrl: apiBaseUrl),
            fallback: fallbackCommunityService,
          );
    return AppDependencies(
      learningRepository: learningRepository,
      communityRepository: communityRepository,
      subscriptionRepository: subscriptionRepository,
      mwalimuAiService: aiService,
      authService: authService,
      communityService: communityService,
      paymentService: paymentService,
      refreshListenable: refreshListenable,
    );
  }

  final LearningRepository learningRepository;
  final CommunityRepository communityRepository;
  final SubscriptionRepository subscriptionRepository;
  final MwalimuAiService mwalimuAiService;
  final AuthService authService;
  final CommunityService communityService;
  final PaymentService paymentService;
  final Listenable? refreshListenable;
}

const _apiBaseUrl = String.fromEnvironment('AJE_API_BASE_URL',
    defaultValue: String.fromEnvironment('MWALIMU_API_BASE_URL'));

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
