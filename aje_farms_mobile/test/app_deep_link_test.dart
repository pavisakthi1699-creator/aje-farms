import 'package:flutter_test/flutter_test.dart';

import 'package:aje_farms_mobile/src/app/app_deep_link.dart';
import 'package:aje_farms_mobile/src/app/main_shell_navigation.dart';

void main() {
  group('AppDeepLinks', () {
    test('parses tab paths', () {
      expect(
        AppDeepLinks.parse('/courses')?.tab,
        MainShellTab.courses,
      );
      expect(
        AppDeepLinks.parse('ajefarms://app/community')?.tab,
        MainShellTab.community,
      );
    });

    test('parses push routes', () {
      expect(
        AppDeepLinks.parse('/paywall')?.kind,
        DeepLinkKind.paywall,
      );
      expect(
        AppDeepLinks.parse('/courses/pasheni')?.id,
        'pasheni',
      );
      expect(
        AppDeepLinks.parse('/community/posts/seed-pasheni-disease')?.id,
        'seed-pasheni-disease',
      );
    });

    test('parses extended push routes', () {
      expect(
        AppDeepLinks.parse('ajefarms://app/problem')?.kind,
        DeepLinkKind.problem,
      );
      expect(
        AppDeepLinks.parse('/settings')?.kind,
        DeepLinkKind.settings,
      );
      expect(
        AppDeepLinks.parse('/profile/saved-documents')?.kind,
        DeepLinkKind.savedDocuments,
      );
      expect(
        AppDeepLinks.parse('/assessments/quiz')?.kind,
        DeepLinkKind.quiz,
      );
      expect(
        AppDeepLinks.parse('/support/whatsapp')?.kind,
        DeepLinkKind.whatsapp,
      );
      expect(
        AppDeepLinks.parse('/chat/session')?.kind,
        DeepLinkKind.aiChatSession,
      );
    });

    test('returns null for unknown paths', () {
      expect(AppDeepLinks.parse('/unknown-route'), isNull);
    });
  });
}
