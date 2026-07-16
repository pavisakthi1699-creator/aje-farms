// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final displayName = session.state.displayName;
    final phoneLabel = displayName ?? session.phoneNumber ?? 'Mgeni';
    final memberLabel = displayName == null
        ? (session.isSignedIn ? 'Mkulima Mwanachama' : 'Mgeni')
        : (session.isSignedIn ? 'Mkulima Mwanachama' : 'Mgeni');
    final subscriptionPlan = session.state.subscriptionPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('Akaunti Yangu')),
      body: AppLayout(
        child: ListView(
          key: AppPageStorage.profile,
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Card(
              color: context.colors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: context.colors.primaryContainer,
                      child: Text(
                        session.isSignedIn ? '+255' : 'AJE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      phoneLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (displayName != null && session.phoneNumber != null)
                      Text(
                        session.phoneNumber!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.muted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    Text(
                      memberLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.muted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hali ya Akaunti',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Icon(Icons.schedule, color: context.colors.secondary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subscriptionPlan == null
                          ? 'Ufikiaji wa kawaida'
                          : 'Premium',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: context.colors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: AppDecorations.pastelPanel(
                          context, context.colors.peach),
                      child: Text(
                        subscriptionPlan == null
                            ? 'Unaweza kusoma mafunzo ya msingi na kuhifadhi maendeleo yako.'
                            : '$subscriptionPlan imewashwa kwenye kifaa hiki. Unaweza kuendelea na masomo na Mwalimu AI.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (subscriptionPlan == null)
                      FilledButton.icon(
                        onPressed: () {
                          AppFeedback.tap();
                          AppNavigator.pushPaywall(context);
                        },
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text('Lipia Kifurushi Sasa'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final phoneNumber = session.phoneNumber;
                          if (phoneNumber != null) {
                            try {
                              await context.dependencies.authService
                                  .cancelSubscription(phoneNumber);
                            } on AuthException catch (error) {
                              if (!context.mounted) return;
                              showSnack(context, error.message);
                              return;
                            }
                          }
                          await session.cancelSubscription();
                          if (!context.mounted) return;
                          showSnack(context, 'Kifurushi kimezimwa.');
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Sitisha Kifurushi'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Shughuli Zangu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  ProfileRow(
                    icon: Icons.menu_book,
                    title: 'Mafunzo yangu',
                    onTap: () =>
                        context.switchMainShellTab(MainShellTab.courses),
                  ),
                  ProfileRow(
                    icon: Icons.description_outlined,
                    title: 'Nyaraka zilizohifadhiwa',
                    subtitle:
                        '${session.state.savedDocumentIds.length} zimehifadhiwa',
                    onTap: () => AppNavigator.pushSavedDocuments(context),
                  ),
                  ProfileRow(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Kazi za vitendo',
                    onTap: () => AppNavigator.pushAssessments(context),
                  ),
                  ProfileRow(
                    icon: Icons.settings_outlined,
                    title: 'Mipangilio',
                    onTap: () => AppNavigator.pushSettings(context),
                  ),
                  ProfileRow(
                    icon: Icons.help_outline,
                    title: 'Msaada / WhatsApp',
                    subtitle: 'Wasiliana nasi kupitia WhatsApp',
                    color: context.colors.success,
                    showDivider: false,
                    onTap: () => AppNavigator.pushWhatsApp(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: () async {
                AppFeedback.tap();
                await session.signOut();
                if (!context.mounted) return;
                AppNavigator.replaceWithOnboarding(context);
              },
              icon: Icon(Icons.logout, color: context.colors.error),
              label: Text(
                'Ondoka kwenye Akaunti',
                style: TextStyle(color: context.colors.error),
              ),
            ),
            Center(
              child: Text(
                'AJE Farms',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.muted,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedDocumentsScreen extends StatelessWidget {
  const SavedDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = context.dependencies.learningRepository.documents;
    final savedIds = context.session.state.savedDocumentIds;
    final saved =
        documents.where((document) => savedIds.contains(document.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nyaraka Zilizohifadhiwa')),
      body: AppLayout(
        child: CustomScrollView(
          key: AppPageStorage.savedDocuments,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (saved.isEmpty)
                    const EmptyState(
                      icon: Icons.bookmark_add_outlined,
                      title: 'Hujaweka nyaraka bado',
                      body:
                          'Chagua nyaraka hapa chini ili uzihifadhi kwa kusoma baadaye.',
                    ),
                  if (saved.isNotEmpty)
                    ...saved.map(
                      (entry) => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpacing.lg),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: AppDecorations.pastelPanel(
                              context,
                              context.colors.surfacePeach,
                            ),
                            child: Icon(
                              Icons.picture_as_pdf_outlined,
                              color: context.colors.primary,
                            ),
                          ),
                          title: Text(
                            entry.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Text(
                            entry.courseTitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colors.muted,
                                    ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Ondoa',
                            icon: const Icon(Icons.bookmark_remove_outlined),
                            onPressed: () {
                              AppFeedback.tap();
                              context.session.removeSavedDocument(entry.id);
                            },
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Nyaraka zote',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              sliver: SliverList.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];
                  final isSaved = savedIds.contains(document.id);
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: AppDecorations.pastelPanel(
                          context,
                          isSaved
                              ? context.colors.primaryContainer
                              : context.colors.surfaceMuted,
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_add_outlined,
                          color: context.colors.primary,
                        ),
                      ),
                      title: Text(
                        document.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        document.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          AppFeedback.tap();
                          if (isSaved) {
                            context.session.removeSavedDocument(document.id);
                          } else {
                            context.session.saveDocument(document.id);
                          }
                        },
                        child: Text(isSaved ? 'Ondoa' : 'Hifadhi'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
  late final TextEditingController _displayNameController;
  bool _initializedProfileFields = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _displayNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedProfileFields) return;
    final sessionState = context.session.state;
    _locationController.text = sessionState.preferredLocation ?? '';
    _displayNameController.text = sessionState.displayName ?? '';
    _initializedProfileFields = true;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = context.session;
    final displayName = _displayNameController.text.trim();
    final location = _locationController.text.trim();
    if (session.isSignedIn && session.phoneNumber != null) {
      try {
        final profile = await context.dependencies.authService.updateProfile(
          phoneNumber: session.phoneNumber!,
          displayName: displayName,
          preferredLocation: location,
        );
        await session.syncProfileFromAuthSession(profile);
      } on AuthException catch (error) {
        if (!mounted) return;
        showSnack(context, error.message);
        return;
      } catch (_) {
        if (!mounted) return;
        showSnack(context, 'Imeshindikana kuhifadhi wasifu.');
        return;
      }
    } else {
      await session.setDisplayName(displayName);
      await session.setPreferredLocation(location);
    }
    if (!mounted) return;
    AppFeedback.success();
    showSnack(context, 'Mipangilio imehifadhiwa.');
  }

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = context.session.state.notificationsEnabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Mipangilio')),
      body: AppLayout(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muonekano wa app',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chagua mwanga, giza, au fuata mipangilio ya kifaa.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<AppThemePreference>(
                      segments: [
                        for (final preference in AppThemePreference.values)
                          ButtonSegment(
                            value: preference,
                            label: Text(preference.label),
                          ),
                      ],
                      selected: {context.session.state.themePreference},
                      onSelectionChanged: (selection) {
                        AppFeedback.selection();
                        context.session.setThemePreference(selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: SwitchListTile(
                value: notificationsEnabled,
                onChanged: (value) {
                  AppFeedback.selection();
                  context.session.setNotificationsEnabled(value);
                },
                contentPadding: const EdgeInsets.all(AppSpacing.lg),
                title: const Text('Arifa za mafunzo na jamii'),
                subtitle: const Text('Washa au zima vikumbusho kwenye app.'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Jina lako',
                    hintText: 'Mfano: Asha',
                    prefixIcon: Icon(Icons.person_outline),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Eneo la kawaida',
                    hintText: 'Mfano: Morogoro',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                AppFeedback.tap();
                _save();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Hifadhi Mipangilio'),
            ),
          ],
        ),
      ),
    );
  }
}
