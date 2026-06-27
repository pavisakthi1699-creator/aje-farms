part of '../app.dart';

class AjeFarmsApp extends StatelessWidget {
  const AjeFarmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJE Farms',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const OnboardingScreen(),
    );
  }
}
