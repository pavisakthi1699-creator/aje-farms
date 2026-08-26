import 'dart:async';

import '../ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _authFlowVersionKey = 'app.auth_flow_version';
  static const _authFlowVersion = 1;

  late final AppDependencies _dependencies =
      widget.dependencies ?? AppDependencies.production();
  late final AppSessionController _sessionController =
      widget.sessionController ?? AppSessionController();
  bool _appliedPendingDeepLink = false;
  bool _isBootstrapping = true;

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
                title: 'Chuo Kikuu Cha Mtaani',
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
                home: _isBootstrapping
                    ? const _AuthenticationBootstrapScreen()
                    : _sessionController.hasStarted
                        ? AccessGate(
                            child: MainShell(
                              initialTab: AppNavigator.pendingInitialTab() ??
                                  MainShellTab.home,
                            ),
                          )
                        : const AuthScreen(),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _restoreAndSyncSession() async {
    try {
      await _sessionController.restore();

      // Older APKs restored both SharedPreferences and Supabase Auth and then
      // skipped the authentication form. Reset that legacy state once. New
      // sessions created with this flow continue to survive ordinary restarts.
      if (widget.sessionController == null &&
          await _resetLegacyAuthenticationIfNeeded()) {
        return;
      }

      // Supabase can retain a credential after an APK update or Android backup.
      // It is not enough to enter the app: our own signed-in state must agree.
      if (!_sessionController.state.hasStarted ||
          _sessionController.state.isGuest) {
        return;
      }
      if (!_dependencies.authService.hasLocalSession) {
        if (widget.sessionController == null) {
          _dependencies.cachedRepository?.clearProtectedContent();
          await _sessionController.signOut();
        }
        return;
      }

      final session = await _dependencies.authService.getSession().timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw const AuthNetworkException(
              'Mtandao umechukua muda mrefu. Jaribu tena.',
            ),
          );
      await _sessionController.signInWithEmail(session.email,
          role: session.role);
      await _sessionController.syncAccountStatusFromAuthSession(session);
      await _sessionController.syncRoleFromAuthSession(session);
      await _sessionController.syncProfileFromAuthSession(session);
      _finishBootstrap();
      unawaited(_syncAuthenticatedContent(session.email));
    } on AuthNetworkException {
      // A temporary outage may retain learner state, but a cached admin role is
      // never enough to expose administration controls.
      await _sessionController.restrictOfflinePrivileges();
    } on AuthException {
      // The server responded but rejected (or could not validate) the session.
      // Fail closed so stale roles and entitlements cannot unlock the shell.
      if (widget.sessionController == null) {
        _dependencies.cachedRepository?.clearProtectedContent();
        try {
          await _dependencies.authService.signOut();
        } on AuthException {
          // Local application state is still cleared below.
        }
        await _sessionController.signOut();
      }
    } on LearningProgressException {
      // Progress sync should not block opening the app.
    } finally {
      _finishBootstrap();
    }
  }

  void _finishBootstrap() {
    if (mounted && _isBootstrapping) {
      setState(() => _isBootstrapping = false);
    }
  }

  Future<void> _syncAuthenticatedContent(String verifiedEmail) async {
    await Future.wait([
      _dependencies.refreshCatalog(),
      () async {
        try {
          final completedLessons =
              await _dependencies.learningProgressService.completedLessons();
          if (_sessionController.email == verifiedEmail) {
            await _sessionController.syncCompletedLessons(completedLessons);
          }
        } on LearningProgressException {
          // Progress refresh is best effort and must not block the shell.
        }
      }(),
    ]);
  }

  Future<bool> _resetLegacyAuthenticationIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    final version = preferences.getInt(_authFlowVersionKey) ?? 0;
    if (version >= _authFlowVersion) return false;

    await preferences.setInt(_authFlowVersionKey, _authFlowVersion);
    final hadRetainedSession = _sessionController.state.hasStarted ||
        _dependencies.authService.hasLocalSession;
    if (!hadRetainedSession) return false;

    try {
      await _dependencies.authService.signOut();
    } on AuthException {
      // Local app state is still cleared below. Startup will not trust a lone
      // Supabase credential, so an offline sign-out cannot bypass this gate.
    }
    await _sessionController.signOut();
    return true;
  }
}

class _AuthenticationBootstrapScreen extends StatelessWidget {
  const _AuthenticationBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
