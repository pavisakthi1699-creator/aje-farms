import 'package:flutter/material.dart';

enum MainShellTab {
  home,
  courses,
  aiChat,
  community,
  profile,
}

class MainShellNavigation extends InheritedWidget {
  const MainShellNavigation({
    required this.selectTab,
    required super.child,
    super.key,
  });

  final ValueChanged<MainShellTab> selectTab;

  static MainShellNavigation of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<MainShellNavigation>();
    assert(result != null, 'MainShellNavigation not found in widget tree.');
    return result!;
  }

  static MainShellNavigation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellNavigation>();
  }

  @override
  bool updateShouldNotify(MainShellNavigation oldWidget) => false;
}

extension MainShellNavigationContext on BuildContext {
  void switchMainShellTab(MainShellTab tab) {
    MainShellNavigation.of(this).selectTab(tab);
  }

  bool get hasMainShellNavigation => MainShellNavigation.maybeOf(this) != null;
}
