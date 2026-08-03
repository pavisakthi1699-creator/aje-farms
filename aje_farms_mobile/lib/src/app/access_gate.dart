import '../ui.dart';

/// The single place the app decides whether a learner may see paid surfaces.
///
/// Before this existed the only access check in the client was the per-lesson
/// `lesson.isPremium && !hasActiveAccess` test in the course detail screen, so
/// an account that had registered but had not been approved still landed in the
/// full shell — home, courses, Mwalimu AI, community — and only discovered the
/// wall on tapping a lesson. Staff read that as "new users get access before we
/// grant it". Every protected entry point now routes through here instead, and
/// the decision fails closed: anything other than a confirmed active account
/// renders [PendingAccessScreen].
///
/// Access itself is still server-owned ([AppSessionState.hasActiveAccess]
/// mirrors `hasPaidLearningAccess`); this only stops the client from rendering
/// ahead of it.
class AccessGate extends StatelessWidget {
  const AccessGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Reading the session here subscribes to it, so an approval that lands
    // while this screen is open swaps in `child` without a restart.
    if (context.session.hasActiveAccess) {
      return child;
    }
    return const PendingAccessScreen();
  }
}
