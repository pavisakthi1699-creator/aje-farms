// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";
import '../../app/build_flags.dart';

/// The wall an account sits behind until staff approve access.
///
/// Registering creates an account, not access: the server only unlocks content
/// once an admin approves a payment and an entitlement row exists (see
/// `hasPaidLearningAccess` in server/api.js). Before that this screen is the
/// whole app, so a learner is told in Swahili that the account is waiting for
/// verification instead of being dropped into a shell whose lessons are all
/// silently blank.
///
/// Wording comes from [AccountAccessStatus] so the home card, the profile card
/// and this screen can never disagree about what state the account is in.
class PendingAccessScreen extends StatefulWidget {
  const PendingAccessScreen({super.key});

  @override
  State<PendingAccessScreen> createState() => PendingAccessScreenState();
}

class PendingAccessScreenState extends State<PendingAccessScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // An approval that lands while the app is closed would otherwise leave the
    // learner staring at this screen until they think to press the button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshAccess(silent: true);
    });
  }

  Future<void> _refreshAccess({bool silent = false}) async {
    if (_isRefreshing) return;
    final appSession = context.session;
    if (appSession.state.isGuest) return;
    setState(() => _isRefreshing = true);
    final dependencies = context.dependencies;
    try {
      final session = await dependencies.authService.getSession();
      final willHaveAccess =
          session.accountStatus == 'active' || session.role == 'admin';
      if (willHaveAccess) {
        // Load the entitled catalog before notifying AccessGate. Publishing
        // the active state first can dispose this screen on the next frame and
        // strand the learner with the locked snapshot fetched at sign-in.
        await dependencies.refreshCatalog();
      }
      await appSession.syncAccountStatusFromAuthSession(session);
      await appSession.syncRoleFromAuthSession(session);
      await appSession.syncProfileFromAuthSession(session);
      if (!mounted) return;
      if (appSession.hasActiveAccess) {
        if (silent) return;
        // Only when the learner asked: on the startup check the app simply
        // opens, and a snack would sit over whatever they tap first.
        AppFeedback.success();
        showSuccessSnack(context, tr('Akaunti yako imewashwa. Karibu!'));
        return;
      }
      if (silent) return;
      showSnack(context, tr('Bado hujawashiwa akaunti. Jaribu tena baadaye.'));
    } on AuthException catch (error) {
      if (!mounted || silent) return;
      showErrorSnack(context, tr(error.message));
    } catch (_) {
      if (!mounted || silent) return;
      showErrorSnack(
        context,
        tr('Imeshindikana kuangalia hali ya akaunti. Angalia mtandao wako.'),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _signOut() async {
    AppFeedback.tap();
    final confirmed = await confirmAction(
      context,
      title: tr('Ondoka kwenye akaunti?'),
      message: tr('Utahitaji kuingia tena kwa barua pepe na nenosiri.'),
      confirmLabel: tr('Ondoka'),
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final dependencies = context.dependencies;
    final session = context.session;
    dependencies.cachedRepository?.clearProtectedContent();
    await dependencies.authService.signOut();
    await session.signOut();
    if (!mounted) return;
    AppNavigator.replaceWithAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.session.state;
    final status = AccountAccessStatus.of(session);
    final isSuspended = status == AccountAccessStatus.suspended;
    final isGuest = status == AccountAccessStatus.guest;
    final email = session.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Hali ya Akaunti')),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        actions: const [LanguageToggleButton()],
      ),
      body: AppLayoutScroll(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        header: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: _PendingBanner(status: status, session: session),
        ),
        bodyPadding: const EdgeInsets.all(AppSpacing.xl),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              status.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (!isGuest) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                isSuspended
                    ? tr(
                        'Ukishasaidiwa na timu, ufikiaji wako utarudi hapa hapa.',
                      )
                    : tr(
                        'Mafunzo yatafunguka mara tu timu ya Chuo Kikuu Cha Mtaani '
                        'itakapothibitisha akaunti yako.',
                      ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.muted,
                    ),
              ),
            ],
            if (email != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                tr('Akaunti: {email}', {'email': email}),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.muted,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const AccessBenefitsCard(),
            if (kPlayConsumptionOnly) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                tr('Programu hii haitoi ununuzi ndani ya programu.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.muted,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              // Nothing to re-check for someone who never signed in: send them
              // to registration instead of to a status they do not have.
              child: isGuest
                  ? FilledButton.icon(
                      onPressed: () {
                        AppFeedback.tap();
                        AppNavigator.pushAuth(context);
                      },
                      icon: const Icon(Icons.person_add_alt),
                      label: Text(tr('Ingia / Jisajili')),
                    )
                  : FilledButton.icon(
                      onPressed: _isRefreshing
                          ? null
                          : () {
                              AppFeedback.tap();
                              _refreshAccess();
                            },
                      icon: _isRefreshing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(tr('Onyesha Hali Upya')),
                    ),
            ),
            if (!isGuest) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: _signOut,
                icon: Icon(Icons.logout, color: context.colors.error),
                label: Text(
                  tr('Ondoka kwenye Akaunti'),
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.status, required this.session});

  final AccountAccessStatus status;
  final AppSessionState session;

  @override
  Widget build(BuildContext context) {
    final isSuspended = status == AccountAccessStatus.suspended;
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isSuspended ? context.colors.error : context.colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppElevation.float(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Pill(
              label: status.shortLabel,
              color: context.colors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              status.title(session),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.onPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
