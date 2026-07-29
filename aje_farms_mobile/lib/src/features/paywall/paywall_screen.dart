// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

/// Shown instead of a self-service checkout: AJE Farms activates paid access
/// after staff record and approve a cash or bank-transfer payment outside the
/// app. This screen deliberately shows no payment instructions or bank
/// details — Google Play does not allow that for digital learning access —
/// only status, a way to check again, and a way to reach support.
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
    final plans = context.dependencies.subscriptionRepository.plans;
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
                  ? 'Uanachama wako umesitishwa. Wasiliana na timu ya AJE Farms kwa msaada.'
                  : 'Timu ya AJE Farms itawasha akaunti yako mara malipo yako yatakapothibitishwa.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const PaymentBenefitsCard(),
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
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  AppFeedback.tap();
                  AppNavigator.pushWhatsApp(context);
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Wasiliana na Timu ya AJE'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Vifurushi vinavyopatikana',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Wasiliana na timu ya AJE Farms au wakala wako kulipia mojawapo ya vifurushi hivi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...plans.map((plan) => _PlanInfoTile(plan: plan)),
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

class _PlanInfoTile extends StatelessWidget {
  const _PlanInfoTile({required this.plan});

  final PlanOption plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
          leading: CircleAvatar(
            backgroundColor: context.colors.surfaceMuted,
            child: Icon(plan.icon, color: context.colors.textPrimary),
          ),
          title: Text(
            plan.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(
            plan.recommended ? 'Inapendekezwa - ${plan.subtitle}' : plan.subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Text(
            plan.price,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
