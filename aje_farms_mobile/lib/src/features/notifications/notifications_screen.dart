// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.session.state;
    final notifications = [
      if (!state.notificationsEnabled)
        const (
          Icons.notifications_off_outlined,
          'Arifa zimezimwa',
          'Washa arifa kwenye mipangilio ili kupata vikumbusho.'
        ),
      if (state.subscriptionPlan == null)
        const (
          Icons.payment,
          'Jaribio linaendelea',
          'Lipia kifurushi ili uendelee kupata mafunzo na AI bila kikomo.'
        )
      else
        (
          Icons.workspace_premium,
          'Kifurushi kipo hai',
          '${state.subscriptionPlan} imewashwa kwenye kifaa hiki.'
        ),
      if (state.assessmentScores.isNotEmpty)
        (
          Icons.quiz_outlined,
          'Matokeo ya tathmini',
          'Umefanya tathmini ${state.assessmentScores.length}. Endelea kujifunza.'
        ),
      if (state.savedDocumentIds.isNotEmpty)
        (
          Icons.bookmark,
          'Nyaraka zimehifadhiwa',
          'Una nyaraka ${state.savedDocumentIds.length} za kusoma baadaye.'
        ),
      if (state.localPosts.isNotEmpty)
        (
          Icons.groups_outlined,
          'Jamii inasubiri',
          'Umetuma post ${state.localPosts.length}. Angalia majibu mapya.'
        ),
      const (
        Icons.menu_book,
        'Somo jipya limeongezwa',
        'Angalia mwongozo mpya wa nyanya na udhibiti wa wadudu.'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in notifications)
            Card(
              child: ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                subtitle: Text(item.$3),
              ),
            ),
        ],
      ),
    );
  }
}
