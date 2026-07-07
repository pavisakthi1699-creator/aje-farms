// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  Future<NotificationInbox>? _inboxFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phoneNumber = context.session.phoneNumber;
    if (phoneNumber != null && context.session.isSignedIn) {
      _inboxFuture ??= context.dependencies.notificationService.inbox(
        phoneNumber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = context.session.phoneNumber;
    final isSignedIn = phoneNumber != null && context.session.isSignedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Arifa')),
      body: AppLayout(
        child: isSignedIn && _inboxFuture != null
          ? FutureBuilder<NotificationInbox>(
              future: _inboxFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: const [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LoadingSkeleton(height: 18, width: 180),
                              SizedBox(height: AppSpacing.sm),
                              LoadingSkeleton(height: 14, width: 240),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final inbox = snapshot.data;
                return FadeInContent(
                  child: ListView(
                    key: AppPageStorage.notifications,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      if (snapshot.hasError)
                        const _NotificationTile(
                          icon: Icons.cloud_off_outlined,
                          title: 'Arifa hazijapatikana',
                          body: 'Tumia mtandao kisha jaribu tena.',
                        ),
                      if (inbox != null) ...[
                        _NotificationTile(
                          icon: inbox.settings.enabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          title: inbox.settings.enabled
                              ? 'Arifa zimewashwa'
                              : 'Arifa zimezimwa',
                          body: inbox.settings.enabled
                              ? 'Tutakutumia majibu mapya na taarifa muhimu.'
                              : 'Washa arifa kwenye mipangilio ili kupata vikumbusho.',
                          accentColor: context.colors.primaryContainer,
                        ),
                        for (final notification in inbox.notifications)
                          _NotificationTile(
                            icon: notification.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.notifications_outlined,
                            title: notification.title,
                            body: notification.body,
                            isUnread: !notification.isRead,
                            trailing: notification.isRead
                                ? null
                                : TextButton(
                                    onPressed: () {
                                      AppFeedback.tap();
                                      _markRead(
                                        phoneNumber,
                                        notification.id,
                                      );
                                    },
                                    child: const Text('Soma'),
                                  ),
                          ),
                        if (inbox.notifications.isEmpty)
                          const _NotificationTile(
                            icon: Icons.inbox_outlined,
                            title: 'Hakuna arifa mpya',
                            body:
                                'Tutakuonyesha majibu ya jamii, taarifa za usimamizi, na vikumbusho hapa.',
                          ),
                      ],
                      ..._localReminderTiles(context),
                    ],
                  ),
                );
              },
            )
          : ListView(
              key: AppPageStorage.notifications,
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: _localReminderTiles(context),
            ),
      ),
    );
  }

  Future<void> _markRead(String phoneNumber, String notificationId) async {
    await context.dependencies.notificationService.markRead(
      phoneNumber: phoneNumber,
      notificationId: notificationId,
    );
    if (!mounted) return;
    setState(() {
      _inboxFuture =
          context.dependencies.notificationService.inbox(phoneNumber);
    });
  }

  List<Widget> _localReminderTiles(BuildContext context) {
    final state = context.session.state;
    return [
      if (state.subscriptionPlan == null)
        _NotificationTile(
          icon: Icons.payment,
          title: 'Jaribio linaendelea',
          body:
              'Lipia kifurushi ili uendelee kupata mafunzo na AI bila kikomo.',
          accentColor: context.colors.surfacePeach,
        )
      else
        _NotificationTile(
          icon: Icons.workspace_premium,
          title: 'Kifurushi kipo hai',
          body: '${state.subscriptionPlan} imewashwa kwenye kifaa hiki.',
          accentColor: context.colors.successSurface,
        ),
      if (state.assessmentScores.isNotEmpty)
        _NotificationTile(
          icon: Icons.quiz_outlined,
          title: 'Matokeo ya tathmini',
          body:
              'Umefanya tathmini ${state.assessmentScores.length}. Endelea kujifunza.',
          accentColor: context.colors.surfaceLavender,
        ),
      if (state.savedDocumentIds.isNotEmpty)
        _NotificationTile(
          icon: Icons.bookmark,
          title: 'Nyaraka zimehifadhiwa',
          body:
              'Una nyaraka ${state.savedDocumentIds.length} za kusoma baadaye.',
          accentColor: context.colors.surfaceAqua,
        ),
      if (state.localPosts.isNotEmpty)
        _NotificationTile(
          icon: Icons.groups_outlined,
          title: 'Jamii inasubiri',
          body:
              'Umetuma post ${state.localPosts.length}. Angalia majibu mapya.',
          accentColor: context.colors.surfaceMuted,
        ),
      _NotificationTile(
        icon: Icons.menu_book,
        title: 'Somo jipya limeongezwa',
        body: 'Angalia mwongozo mpya wa nyanya na udhibiti wa wadudu.',
        accentColor: context.colors.primaryContainer,
      ),
    ];
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
    this.isUnread = false,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;
  final bool isUnread;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final panelColor = accentColor ?? context.colors.surfaceMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        color: isUnread ? context.colors.surface : context.colors.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isUnread
                ? Border.all(
                    color: context.colors.primary.withValues(alpha: 0.28),
                    width: 1.5,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: AppDecorations.pastelPanel(context, panelColor),
                  child: Icon(icon, color: context.colors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(
                                left: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.muted,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
