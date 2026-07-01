import 'package:flutter/widgets.dart';

import '../repositories/community_repository.dart';
import '../repositories/demo_app_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/subscription_repository.dart';
import '../services/demo_mwalimu_ai_service.dart';
import '../services/mwalimu_ai_service.dart';

class AppDependencies {
  const AppDependencies({
    required this.learningRepository,
    required this.communityRepository,
    required this.subscriptionRepository,
    required this.mwalimuAiService,
  });

  factory AppDependencies.demo() {
    const repository = DemoAppRepository();
    return const AppDependencies(
      learningRepository: repository,
      communityRepository: repository,
      subscriptionRepository: repository,
      mwalimuAiService: DemoMwalimuAiService(),
    );
  }

  final LearningRepository learningRepository;
  final CommunityRepository communityRepository;
  final SubscriptionRepository subscriptionRepository;
  final MwalimuAiService mwalimuAiService;
}

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
