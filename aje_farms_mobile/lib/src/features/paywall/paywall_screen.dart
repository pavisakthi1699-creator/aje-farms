// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";
import '../../app/build_flags.dart';

/// Consumption-only access status. The Play app neither sells digital access
/// nor directs a learner to an external purchase flow.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => PaywallScreenState();
}

class PaywallScreenState extends State<PaywallScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshAccess() async {
    setState(() => _isRefreshing = true);
    final appSession = context.session;
    final authService = context.dependencies.authService;
    try {
      final session = await authService.getSession();
      await appSession.syncAccountStatusFromAuthSession(session);
      await appSession.syncRoleFromAuthSession(session);
      if (!mounted) return;
      if (session.hasActiveAccess) {
        AppFeedback.success();
        showSuccessSnack(context, 'Akaunti yako imewashwa. Karibu!');
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      showSnack(context, 'Bado hujawashiwa akaunti. Jaribu tena baadaye.');
    } on AuthException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Imeshindikana kuangalia hali ya akaunti. Angalia mtandao wako.',
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.session.state.accountStatus;
    final isSuspended = status == 'suspended';

    return Scaffold(
      appBar: AppBar(title: const Text('Hali ya Uanachama')),
      body: AppLayoutScroll(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        header: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: _StatusBanner(isSuspended: isSuspended),
        ),
        bodyPadding: const EdgeInsets.all(AppSpacing.xl),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSuspended
                  ? 'Uanachama wako umesitishwa. Wasiliana na timu ya Chuo Kikuu Cha Mtaani kwa msaada.'
                  : 'Timu ya Chuo Kikuu Cha Mtaani bado inakagua na kuandaa ufikiaji wa akaunti yako.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AccessBenefitsCard(),
            if (kPlayConsumptionOnly) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Programu hii haitoi ununuzi ndani ya programu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.muted,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
                label: const Text('Onyesha Hali Upya'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isSuspended});

  final bool isSuspended;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
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
              label: isSuspended ? 'Imesitishwa' : 'Inasubiri Uthibitisho',
              color: context.colors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isSuspended ? 'Ufikiaji umesitishwa' : 'Akaunti bado haijawashwa',
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
