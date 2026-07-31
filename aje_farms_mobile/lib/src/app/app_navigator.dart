import '../ui.dart';
import 'app_deep_link.dart';
import 'app_route_args.dart';
import 'app_routes.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();

  static String? pendingDeepLink;

  static void captureInitialRoute() {
    final route =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName.trim();
    if (route.isNotEmpty && route != '/') {
      pendingDeepLink = route;
    }
  }

  static MainShellTab? pendingInitialTab() {
    final target = AppDeepLinks.parse(pendingDeepLink ?? '');
    if (target?.kind == DeepLinkKind.tab) {
      return target!.tab;
    }
    return null;
  }

  static void applyPending(BuildContext context) {
    final link = pendingDeepLink;
    if (link == null) {
      return;
    }
    final target = AppDeepLinks.parse(link);
    if (target?.kind == DeepLinkKind.tab) {
      pendingDeepLink = null;
      return;
    }
    pendingDeepLink = null;
    handleDeepLink(context, link);
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null) {
      return null;
    }

    switch (name) {
      case AppRoutes.paywall:
        return _page(settings, const PaywallScreen());
      case AppRoutes.notifications:
        return _page(settings, const NotificationsScreen());
      case AppRoutes.auth:
        return _page(settings, const AuthScreen());
      case AppRoutes.passwordReset:
        return _page(settings, const PasswordResetScreen());
      case AppRoutes.onboarding:
        return _page(settings, const OnboardingScreen());
      case AppRoutes.problem:
        return _page(settings, const ProblemScreen());
      case AppRoutes.settings:
        return _page(settings, const SettingsScreen());
      case AppRoutes.adminDashboard:
        return _page(settings, const AdminDashboardScreen());
      case AppRoutes.savedDocuments:
        return _page(settings, const SavedDocumentsScreen());
      case AppRoutes.assessments:
        return _page(settings, const AssessmentsScreen());
      case AppRoutes.fieldAssignment:
        return _page(settings, const FieldAssignmentScreen());
      case AppRoutes.whatsapp:
        return _page(settings, const WhatsAppEscalationScreen());
      case AppRoutes.createCommunityPost:
        return _page(settings, const CreateCommunityPostScreen());
      case AppRoutes.aiChatSession:
        final args = settings.arguments as AiChatRouteArgs?;
        return _page(
          settings,
          AiChatScreen(
            initialPromptTopic: args?.initialPromptTopic,
            initialPromptDetail: args?.initialPromptDetail,
            initialPrompt: args?.initialPrompt,
          ),
        );
    }

    if (name.startsWith(AppRoutes.coursePrefix)) {
      final courseId = name.substring(AppRoutes.coursePrefix.length);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final course = _findCourse(context, courseId);
          if (course == null) {
            return const _DeepLinkMissingScreen(
              message: 'Kozi haikupatikana kwa kiungo hiki.',
            );
          }
          return CourseDetailScreen(course: course);
        },
      );
    }
    if (name.startsWith(AppRoutes.communityPostPrefix)) {
      final postId = name.substring(AppRoutes.communityPostPrefix.length);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final post = _findCommunityPost(context, postId);
          if (post == null) {
            return const _DeepLinkMissingScreen(
              message: 'Post ya jamii haikupatikana kwa kiungo hiki.',
            );
          }
          return CommunityPostDetailScreen(post: post);
        },
      );
    }

    return null;
  }

  static MaterialPageRoute<void> _page(RouteSettings settings, Widget child) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => child,
    );
  }

  static Future<void> pushPaywall(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.paywall);
  }

  static Future<void> pushNotifications(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.notifications);
  }

  static Future<void> pushAuth(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.auth);
  }

  static Future<void> pushProblem(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.problem);
  }

  static Future<void> pushSettings(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.settings);
  }

  static Future<void> pushAdminDashboard(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
  }

  static Future<void> pushSavedDocuments(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.savedDocuments);
  }

  static Future<void> pushAssessments(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.assessments);
  }

  static Future<void> pushFieldAssignment(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.fieldAssignment);
  }

  static Future<void> pushWhatsApp(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.whatsapp);
  }

  static Future<void> pushCreateCommunityPost(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.createCommunityPost);
  }

  static Future<void> pushCourse(BuildContext context, Course course) {
    return Navigator.of(context).pushNamed(AppRoutes.course(course.id));
  }

  static Future<void> pushCommunityPost(
    BuildContext context,
    CommunityPost post,
  ) {
    return Navigator.of(context).pushNamed(AppRoutes.communityPost(post.id));
  }

  static Future<void> pushAiChat(
    BuildContext context, {
    String? initialPromptTopic,
    String? initialPromptDetail,
    String? initialPrompt,
  }) {
    return Navigator.of(context).pushNamed(
      AppRoutes.aiChatSession,
      arguments: AiChatRouteArgs(
        initialPromptTopic: initialPromptTopic,
        initialPromptDetail: initialPromptDetail,
        initialPrompt: initialPrompt,
      ),
    );
  }

  static Future<void> replaceWithMainShell(
    BuildContext context, {
    MainShellTab tab = MainShellTab.home,
  }) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: AppRoutes.tabPath(tab)),
        builder: (_) => MainShell(initialTab: tab),
      ),
      (_) => false,
    );
  }

  static Future<void> replaceWithOnboarding(BuildContext context) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.onboarding),
        builder: (_) => const OnboardingScreen(),
      ),
      (_) => false,
    );
  }

  static void openMainShellTab(BuildContext context, MainShellTab tab) {
    final navigation = MainShellNavigation.maybeOf(context);
    if (navigation != null) {
      navigation.selectTab(tab);
      return;
    }
    replaceWithMainShell(context, tab: tab);
  }

  static void handleDeepLink(BuildContext context, String input) {
    final target = AppDeepLinks.parse(input);
    if (target == null) {
      return;
    }

    switch (target.kind) {
      case DeepLinkKind.tab:
        if (target.tab != null) {
          openMainShellTab(context, target.tab!);
        }
        break;
      case DeepLinkKind.paywall:
        pushPaywall(context);
        break;
      case DeepLinkKind.notifications:
        pushNotifications(context);
        break;
      case DeepLinkKind.auth:
        pushAuth(context);
        break;
      case DeepLinkKind.passwordReset:
        Navigator.of(context).pushNamed(AppRoutes.passwordReset);
        break;
      case DeepLinkKind.onboarding:
        replaceWithOnboarding(context);
        break;
      case DeepLinkKind.problem:
        pushProblem(context);
        break;
      case DeepLinkKind.settings:
        pushSettings(context);
        break;
      case DeepLinkKind.savedDocuments:
        pushSavedDocuments(context);
        break;
      case DeepLinkKind.assessments:
        pushAssessments(context);
        break;
      case DeepLinkKind.fieldAssignment:
        pushFieldAssignment(context);
        break;
      case DeepLinkKind.whatsapp:
        pushWhatsApp(context);
        break;
      case DeepLinkKind.createCommunityPost:
        pushCreateCommunityPost(context);
        break;
      case DeepLinkKind.aiChatSession:
        pushAiChat(context);
        break;
      case DeepLinkKind.course:
        if (target.id != null) {
          Navigator.of(context).pushNamed(AppRoutes.course(target.id!));
        }
        break;
      case DeepLinkKind.communityPost:
        if (target.id != null) {
          Navigator.of(context).pushNamed(AppRoutes.communityPost(target.id!));
        }
        break;
    }
  }

  static Course? _findCourse(BuildContext context, String courseId) {
    final courses = context.dependencies.learningRepository.courses;
    for (final course in courses) {
      if (course.id == courseId) {
        return course;
      }
    }
    return null;
  }

  static CommunityPost? _findCommunityPost(
      BuildContext context, String postId) {
    final posts = context.session.state.communityPostsMergedWith(
      context.dependencies.communityRepository.posts,
    );
    for (final post in posts) {
      if (post.id == postId) {
        return post;
      }
    }
    return null;
  }
}

class _DeepLinkMissingScreen extends StatelessWidget {
  const _DeepLinkMissingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AJE Farms')),
      body: AppLayout(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            icon: Icons.link_off_outlined,
            title: 'Kiungo hakipatikani',
            body: message,
            actionLabel: 'Rudi',
            onAction: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}
