import 'package:flutter/material.dart';

import '../app/app_dependencies.dart';
import '../state/app_session.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_a11y.dart';
import '../theme/app_feedback.dart';
import '../theme/app_decorations.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'main_shell_navigation.dart';
import 'app_navigator.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/community/community_screen.dart';
import '../features/courses/courses_screen.dart';
import '../features/home/dashboard_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    this.initialTab = MainShellTab.home,
    super.key,
  });

  final MainShellTab initialTab;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index = widget.initialTab.index;

  static const _screens = [
    DashboardScreen(),
    CoursesScreen(),
    AiChatScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  static List<_ShellDestination> get _destinations => [
        _ShellDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: tr('Nyumbani'),
        ),
        _ShellDestination(
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          label: tr('Mafunzo'),
        ),
        _ShellDestination(
          icon: Icons.smart_toy_outlined,
          selectedIcon: Icons.smart_toy,
          label: tr('Uliza AI'),
        ),
        _ShellDestination(
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: tr('Jamii'),
        ),
        _ShellDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: tr('Akaunti'),
        ),
      ];

  void _selectTab(MainShellTab tab) {
    if (tab.index != _index) {
      AppFeedback.selection();
    }
    setState(() => _index = tab.index);
  }

  void _selectIndex(int value) {
    if (value != _index) {
      AppFeedback.selection();
    }
    setState(() => _index = value);
  }

  Widget _buildBody() {
    return Column(
      children: [
        OfflineBanner(
          showCatalogStale: AppSessionScope.of(context).isSignedIn &&
              AppDependenciesScope.of(context)
                      .cachedRepository
                      ?.lastRefreshFailed ==
                  true,
        ),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: _screens,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final useRail = AppBreakpoints.useNavigationRail(context);
    final isCompact =
        MediaQuery.sizeOf(context).width < AppA11y.compactBreakpoint;
    final navPadding = isCompact ? AppSpacing.sm : AppSpacing.lg;

    return MainShellNavigation(
      selectTab: _selectTab,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: useRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _selectIndex,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildBody()),
                ],
              )
            : _buildBody(),
        bottomNavigationBar: useRail
            ? null
            : Padding(
                padding: EdgeInsets.fromLTRB(
                  navPadding,
                  0,
                  navPadding,
                  AppSpacing.md,
                ),
                child: DecoratedBox(
                  decoration: AppDecorations.surfaceCard(context,
                      radius: AppRadius.hero),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                    child: NavigationBar(
                      selectedIndex: _index,
                      animationDuration:
                          AppMotion.durationOf(context, AppMotion.standard),
                      onDestinationSelected: _selectIndex,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: [
                        for (final destination in _destinations)
                          NavigationDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(destination.selectedIcon),
                            label: destination.label,
                            tooltip: destination.label,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

void openMainShellTab(BuildContext context, MainShellTab tab) {
  AppNavigator.openMainShellTab(context, tab);
}
