import '../ui.dart';

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
  late final AppSessionController _sessionController =
      widget.sessionController ?? AppSessionController();

  @override
  void initState() {
    super.initState();
    _sessionController.restore();
  }

  @override
  void dispose() {
    if (widget.sessionController == null) {
      _sessionController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDependenciesScope(
      dependencies: widget.dependencies ?? AppDependencies.localFirst(),
      child: AppSessionScope(
        controller: _sessionController,
        child: AnimatedBuilder(
          animation: _sessionController,
          builder: (context, _) {
            return MaterialApp(
              title: 'AJE Farms',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: _sessionController.hasStarted
                  ? const MainShell()
                  : const OnboardingScreen(),
            );
          },
        ),
      ),
    );
  }
}
