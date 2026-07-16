import 'app_routes.dart';
import 'main_shell_navigation.dart';

enum DeepLinkKind {
  tab,
  paywall,
  notifications,
  auth,
  onboarding,
  problem,
  settings,
  savedDocuments,
  assessments,
  fieldAssignment,
  whatsapp,
  createCommunityPost,
  aiChatSession,
  course,
  communityPost,
}

class DeepLinkTarget {
  const DeepLinkTarget._(this.kind, {this.tab, this.id});

  const DeepLinkTarget.tab(MainShellTab tab)
      : this._(DeepLinkKind.tab, tab: tab);

  const DeepLinkTarget.paywall() : this._(DeepLinkKind.paywall);

  const DeepLinkTarget.notifications() : this._(DeepLinkKind.notifications);

  const DeepLinkTarget.auth() : this._(DeepLinkKind.auth);

  const DeepLinkTarget.onboarding() : this._(DeepLinkKind.onboarding);

  const DeepLinkTarget.problem() : this._(DeepLinkKind.problem);

  const DeepLinkTarget.settings() : this._(DeepLinkKind.settings);

  const DeepLinkTarget.savedDocuments() : this._(DeepLinkKind.savedDocuments);

  const DeepLinkTarget.assessments() : this._(DeepLinkKind.assessments);

  const DeepLinkTarget.fieldAssignment() : this._(DeepLinkKind.fieldAssignment);

  const DeepLinkTarget.whatsapp() : this._(DeepLinkKind.whatsapp);

  const DeepLinkTarget.createCommunityPost()
      : this._(DeepLinkKind.createCommunityPost);

  const DeepLinkTarget.aiChatSession() : this._(DeepLinkKind.aiChatSession);

  const DeepLinkTarget.course(String id) : this._(DeepLinkKind.course, id: id);

  const DeepLinkTarget.communityPost(String id)
      : this._(DeepLinkKind.communityPost, id: id);

  final DeepLinkKind kind;
  final MainShellTab? tab;
  final String? id;
}

abstract final class AppDeepLinks {
  /// Parses cold-start routes, `ajefarms://app/...` URIs, or plain paths.
  static DeepLinkTarget? parse(String input) {
    final path = _normalizePath(input);
    if (path == null || path.isEmpty || path == '/') {
      return null;
    }

    final tab = AppRoutes.tabForPath(path);
    if (tab != null) {
      return DeepLinkTarget.tab(tab);
    }

    return switch (path) {
      AppRoutes.paywall => const DeepLinkTarget.paywall(),
      AppRoutes.notifications => const DeepLinkTarget.notifications(),
      AppRoutes.auth => const DeepLinkTarget.auth(),
      AppRoutes.onboarding => const DeepLinkTarget.onboarding(),
      AppRoutes.problem => const DeepLinkTarget.problem(),
      AppRoutes.settings => const DeepLinkTarget.settings(),
      AppRoutes.savedDocuments => const DeepLinkTarget.savedDocuments(),
      AppRoutes.assessments => const DeepLinkTarget.assessments(),
      AppRoutes.fieldAssignment => const DeepLinkTarget.fieldAssignment(),
      AppRoutes.whatsapp => const DeepLinkTarget.whatsapp(),
      AppRoutes.createCommunityPost =>
        const DeepLinkTarget.createCommunityPost(),
      AppRoutes.aiChatSession => const DeepLinkTarget.aiChatSession(),
      _ when path.startsWith(AppRoutes.coursePrefix) =>
        DeepLinkTarget.course(path.substring(AppRoutes.coursePrefix.length)),
      _ when path.startsWith(AppRoutes.communityPostPrefix) =>
        DeepLinkTarget.communityPost(
          path.substring(AppRoutes.communityPostPrefix.length),
        ),
      _ => null,
    };
  }

  static String? _normalizePath(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.contains('://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null) {
        return null;
      }
      if (uri.path.isNotEmpty) {
        return uri.path;
      }
      if (uri.host.isNotEmpty) {
        return uri.host.startsWith('/') ? uri.host : '/${uri.host}';
      }
      return null;
    }

    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
