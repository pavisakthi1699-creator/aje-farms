import 'main_shell_navigation.dart';

/// Named routes for push navigation and deep links (`ajefarms://app/...`).
abstract final class AppRoutes {
  static const paywall = '/paywall';
  static const notifications = '/notifications';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const problem = '/problem';
  static const settings = '/settings';
  static const savedDocuments = '/profile/saved-documents';
  static const assessments = '/assessments';
  static const fieldAssignment = '/assessments/field';
  static const whatsapp = '/support/whatsapp';
  static const createCommunityPost = '/community/new';
  static const aiChatSession = '/chat/session';

  static const home = '/home';
  static const courses = '/courses';
  static const chat = '/chat';
  static const community = '/community';
  static const profile = '/profile';

  static const coursePrefix = '/courses/';
  static const communityPostPrefix = '/community/posts/';

  static String course(String id) => '$coursePrefix$id';
  static String communityPost(String id) => '$communityPostPrefix$id';

  static String? tabPath(MainShellTab tab) {
    return switch (tab) {
      MainShellTab.home => home,
      MainShellTab.courses => courses,
      MainShellTab.aiChat => chat,
      MainShellTab.community => community,
      MainShellTab.profile => profile,
    };
  }

  static MainShellTab? tabForPath(String path) {
    return switch (path) {
      '/' || home => MainShellTab.home,
      courses => MainShellTab.courses,
      chat || '/ai' => MainShellTab.aiChat,
      community => MainShellTab.community,
      profile => MainShellTab.profile,
      _ => null,
    };
  }
}
