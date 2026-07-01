// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandHeader(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Pill(
                                label: '24h Jaribio la bure',
                                color: AppColors.secondary,
                              ),
                              const Spacer(),
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.agriculture,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Kilimo na Ujasiliamali',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Pata mafunzo, uliza Mwalimu AI, shiriki na wakulima, na ongea na mtaalamu unapohitaji msaada.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const OnboardingValueRow(
                                icon: Icons.smart_toy_outlined,
                                label:
                                    'Majibu ya haraka kwa changamoto za shamba',
                              ),
                              const SizedBox(height: 10),
                              const OnboardingValueRow(
                                icon: Icons.menu_book_outlined,
                                label: 'Masomo ya vitendo kwa mazao na mifugo',
                              ),
                              const SizedBox(height: 10),
                              const OnboardingValueRow(
                                icon: Icons.support_agent,
                                label: 'Msaada wa mtaalamu kupitia WhatsApp',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          await context.session.startAsGuest();
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const MainShell()),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Anza Sasa'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        ),
                        icon: const Icon(Icons.phone_iphone),
                        label: const Text('Ingia / Jisajili'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class OnboardingValueRow extends StatelessWidget {
  const OnboardingValueRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
