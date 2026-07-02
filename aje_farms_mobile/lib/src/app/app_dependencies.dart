import 'package:flutter/widgets.dart';

import '../repositories/community_repository.dart';
import '../repositories/demo_app_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/subscription_repository.dart';
import '../services/auth_service.dart';
import '../services/backend_auth_service.dart';
import '../services/backend_mwalimu_ai_service.dart';
import '../services/backend_payment_service.dart';
import '../services/demo_mwalimu_ai_service.dart';
import '../services/local_auth_service.dart';
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
    required this.paymentService,
  });

  factory AppDependencies.demo() {
    const repository = DemoAppRepository();
    return const AppDependencies(
      learningRepository: repository,
      communityRepository: repository,
      subscriptionRepository: repository,
      mwalimuAiService: DemoMwalimuAiService(),
      authService: LocalAuthService(),
      paymentService: LocalPaymentService(),
    );
  }

  factory AppDependencies.localFirst() {
    const repository = DemoAppRepository();
    const fallbackAiService = DemoMwalimuAiService();
    const fallbackAuthService = LocalAuthService();
    const fallbackPaymentService = LocalPaymentService();
    final apiBaseUrl = Uri.tryParse(_apiBaseUrl);
    final aiService =
        apiBaseUrl == null || !apiBaseUrl.hasScheme || apiBaseUrl.host.isEmpty
            ? fallbackAiService
            : FallbackMwalimuAiService(
                primary: BackendMwalimuAiService(baseUrl: apiBaseUrl),
                fallback: fallbackAiService,
              );
    final authService =
        apiBaseUrl == null || !apiBaseUrl.hasScheme || apiBaseUrl.host.isEmpty
            ? fallbackAuthService
            : FallbackAuthService(
                primary: BackendAuthService(baseUrl: apiBaseUrl),
                fallback: fallbackAuthService,
              );
    final paymentService =
        apiBaseUrl == null || !apiBaseUrl.hasScheme || apiBaseUrl.host.isEmpty
            ? fallbackPaymentService
            : FallbackPaymentService(
                primary: BackendPaymentService(baseUrl: apiBaseUrl),
                fallback: fallbackPaymentService,
              );

    return AppDependencies(
      learningRepository: repository,
      communityRepository: repository,
      subscriptionRepository: repository,
      mwalimuAiService: aiService,
      authService: authService,
      paymentService: paymentService,
    );
  }

  final LearningRepository learningRepository;
  final CommunityRepository communityRepository;
  final SubscriptionRepository subscriptionRepository;
  final MwalimuAiService mwalimuAiService;
  final AuthService authService;
  final PaymentService paymentService;
}

const _apiBaseUrl = String.fromEnvironment('AJE_API_BASE_URL',
    defaultValue: String.fromEnvironment('MWALIMU_API_BASE_URL'));

class AppDependenciesScope extends InheritedWidget {
  const AppDependenciesScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'AppDependenciesScope was not found in the tree.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

extension AppDependenciesContext on BuildContext {
  AppDependencies get dependencies => AppDependenciesScope.of(this);
}
