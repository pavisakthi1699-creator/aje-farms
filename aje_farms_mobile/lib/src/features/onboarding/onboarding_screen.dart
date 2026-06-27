part of '../../app.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.agriculture, color: Colors.white, size: 72),
                      SizedBox(height: 24),
                      Text(
                        'Kilimo na Ujasiliamali',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Jifunze kilimo kwa vitendo, fanya tathmini, uliza AI, na ongea na mtaalamu unapohitaji.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                ),
                child: const Text('Anza Sasa'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
                child: const Text('Ingia / Jisajili'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
