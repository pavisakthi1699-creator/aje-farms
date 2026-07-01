// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final phoneLabel = session.phoneNumber ?? 'Mgeni wa demo';
    final memberLabel =
        session.isSignedIn ? 'Mkulima Mwanachama' : 'Mgeni wa Demo';
    final subscriptionPlan = session.state.subscriptionPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('Akaunti Yangu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryContainer,
            child: Text(session.isSignedIn ? '+255' : 'AJE',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              phoneLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Center(
              child: Text(memberLabel,
                  style: const TextStyle(color: AppColors.muted))),
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
                  Text(
                      subscriptionPlan == null
                          ? 'Majaribio (Trial)'
                          : 'Premium',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(subscriptionPlan == null
                        ? 'Muda wako wa majaribio unaendelea. Jiunge sasa ili uendelee kupata ushauri baada ya trial.'
                        : '$subscriptionPlan imewashwa kwenye kifaa hiki. Unaweza kuendelea na masomo na Mwalimu AI.'),
                  ),
                  const SizedBox(height: 16),
                  if (subscriptionPlan == null)
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PaywallScreen()),
                      ),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('Lipia Kifurushi Sasa'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        await session.cancelSubscription();
                        if (!context.mounted) return;
                        showSnack(context, 'Kifurushi kimezimwa kwenye kifaa.');
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Sitisha Kifurushi'),
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
                ProfileRow(
                  icon: Icons.menu_book,
                  title: 'Mafunzo yangu',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CoursesScreen()),
                  ),
                ),
                ProfileRow(
                  icon: Icons.description_outlined,
                  title: 'Nyaraka zilizohifadhiwa',
                  subtitle:
                      '${session.state.savedDocumentIds.length} zimehifadhiwa',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SavedDocumentsScreen()),
                  ),
                ),
                ProfileRow(
                  icon: Icons.quiz_outlined,
                  title: 'Tathmini na kazi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AssessmentsScreen()),
                  ),
                ),
                ProfileRow(
                  icon: Icons.settings_outlined,
                  title: 'Mipangilio',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                ProfileRow(
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
            onPressed: () async {
              await session.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (_) => false,
              );
            },
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

class SavedDocumentsScreen extends StatelessWidget {
  const SavedDocumentsScreen({super.key});

  static const _documents = {
    'pasheni-guide': 'Mwongozo mfupi wa pasheni',
    'kuku-vaccines': 'Ratiba ya chanjo ya kuku',
    'nyanya-pests': 'Udhibiti wa wadudu kwenye nyanya',
  };

  @override
  Widget build(BuildContext context) {
    final savedIds = context.session.state.savedDocumentIds;
    final saved = _documents.entries
        .where((entry) => savedIds.contains(entry.key))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nyaraka Zilizohifadhiwa')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (saved.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Hujaweka nyaraka bado. Chagua nyaraka hapa chini ili uzihifadhi kwa kusoma baadaye.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          if (saved.isNotEmpty)
            ...saved.map(
              (entry) => Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(entry.value),
                  subtitle: const Text('Imehifadhiwa kwa kusoma baadaye'),
                  trailing: IconButton(
                    tooltip: 'Ondoa',
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    onPressed: () =>
                        context.session.removeSavedDocument(entry.key),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('Nyaraka zote', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._documents.entries.map(
            (entry) {
              final isSaved = savedIds.contains(entry.key);
              return ListTile(
                leading: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_add_outlined),
                title: Text(entry.value),
                trailing: TextButton(
                  onPressed: () => isSaved
                      ? context.session.removeSavedDocument(entry.key)
                      : context.session.saveDocument(entry.key),
                  child: Text(isSaved ? 'Ondoa' : 'Hifadhi'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: context.session.state.preferredLocation ?? '',
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.session.setPreferredLocation(_locationController.text);
    if (!mounted) return;
    showSnack(context, 'Mipangilio imehifadhiwa.');
  }

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = context.session.state.notificationsEnabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Mipangilio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: context.session.setNotificationsEnabled,
            title: const Text('Arifa za mafunzo na jamii'),
            subtitle: const Text('Washa au zima vikumbusho kwenye app.'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Eneo la kawaida',
              hintText: 'Mfano: Morogoro',
              prefixIcon: const Icon(Icons.place_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Hifadhi Mipangilio'),
          ),
        ],
      ),
    );
  }
}
