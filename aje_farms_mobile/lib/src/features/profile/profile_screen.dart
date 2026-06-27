part of '../../app.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akaunti Yangu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryContainer,
            child: Text('+255',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '+255 7XX XXX XXX',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const Center(
              child: Text('Mkulima Mwanachama',
                  style: TextStyle(color: AppColors.muted))),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text('Hali ya Akaunti',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      Icon(Icons.schedule, color: AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Majaribio (Trial)',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                        'Muda wako wa majaribio unakwisha baada ya saa 2. Jiunge sasa ili uendelee kupata ushauri.'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    ),
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Lipia Kifurushi Sasa'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Shughuli Zangu',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.menu_book,
                  title: 'Mafunzo yangu',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CoursesScreen()),
                  ),
                ),
                _ProfileRow(
                  icon: Icons.description_outlined,
                  title: 'Nyaraka zilizohifadhiwa',
                  onTap: () => _showSnack(
                      context, 'Nyaraka zilizohifadhiwa zitaonekana hapa.'),
                ),
                _ProfileRow(
                  icon: Icons.quiz_outlined,
                  title: 'Tathmini na kazi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AssessmentsScreen()),
                  ),
                ),
                _ProfileRow(
                  icon: Icons.settings_outlined,
                  title: 'Mipangilio',
                  onTap: () =>
                      _showSnack(context, 'Mipangilio itaunganishwa baadaye.'),
                ),
                _ProfileRow(
                  icon: Icons.help_outline,
                  title: 'Msaada / WhatsApp',
                  subtitle: 'Tupo kwa ajili yako 24/7',
                  color: Colors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WhatsAppEscalationScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () =>
                _showSnack(context, 'Umeondoka kwenye akaunti ya mfano.'),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Ondoka kwenye Akaunti',
                style: TextStyle(color: Colors.red)),
          ),
          const Center(
              child: Text('Toleo la App 2.4.0',
                  style: TextStyle(color: AppColors.muted, fontSize: 11))),
        ],
      ),
    );
  }
}
