import '../ui.dart';
import 'package:flutter/services.dart';

class AjeFarmsApp extends StatefulWidget {
  const AjeFarmsApp({
    this.dependencies,
    this.sessionController,
    super.key,
  });

  final AppDependencies? dependencies;
  final AppSessionController? sessionController;

  @override
  State<AjeFarmsApp> createState() => AjeFarmsAppState();
}

class AjeFarmsAppState extends State<AjeFarmsApp> {
  late final AppDependencies _dependencies =
      widget.dependencies ?? AppDependencies.production();
  late final AppSessionController _sessionController =
      widget.sessionController ?? AppSessionController();
  bool _appliedPendingDeepLink = false;

  @override
  void initState() {
    super.initState();
    AppNavigator.captureInitialRoute();
    _restoreAndSyncSession();
  }

  @override
  void dispose() {
    if (widget.sessionController == null) {
      _sessionController.dispose();
    }
    super.dispose();
  }

  ThemeMode _themeMode(AppThemePreference preference) {
    return switch (preference) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.system => ThemeMode.system,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityScope(
      child: AppDependenciesScope(
        dependencies: _dependencies,
        child: AppSessionScope(
          controller: _sessionController,
          child: AnimatedBuilder(
            animation: _sessionController,
            builder: (context, _) {
              if (_sessionController.hasStarted && !_appliedPendingDeepLink) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _appliedPendingDeepLink) {
                    return;
                  }
                  _appliedPendingDeepLink = true;
                  final navContext = AppNavigator.rootKey.currentContext;
                  if (navContext != null) {
                    AppNavigator.applyPending(navContext);
                  }
                });
              }
              return MaterialApp(
                title: 'AJE Farms',
                debugShowCheckedModeBanner: false,
                navigatorKey: AppNavigator.rootKey,
                restorationScopeId: 'aje_farms_app',
                onGenerateRoute: AppNavigator.onGenerateRoute,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: _themeMode(_sessionController.state.themePreference),
                builder: (context, child) {
                  final overlayStyle =
                      AppTheme.overlayStyle(Theme.of(context).brightness);
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: overlayStyle,
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: _sessionController.hasStarted
                    ? MainShell(
                        initialTab: AppNavigator.pendingInitialTab() ??
                            MainShellTab.home,
                      )
                    : const OnboardingScreen(),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _restoreAndSyncSession() async {
    await _sessionController.restore();
    // Supabase itself already restored its session (if any) before this app
    // widget was built (see main.dart); this only needs to check whether one
    // exists and, if so, refresh role/accountStatus/profile from the backend.
    if (_sessionController.state.isGuest ||
        !_dependencies.authService.hasLocalSession) {
      return;
    }

    try {
      final session = await _dependencies.authService.getSession();
      await _sessionController.signInWithEmail(session.email,
          role: session.role);
      await _sessionController.syncAccountStatusFromAuthSession(session);
      await _sessionController.syncRoleFromAuthSession(session);
      await _sessionController.syncProfileFromAuthSession(session);
      await _dependencies.refreshCatalog();
      final completedLessons =
          await _dependencies.learningProgressService.completedLessons();
      await _sessionController.syncCompletedLessons(completedLessons);
    } on AuthException {
      // Keep the locally restored session usable when the backend is temporarily
      // unreachable. Mutating actions still require backend success.
    } on LearningProgressException {
      // Progress sync should not block opening the app.
    }
  }
}
