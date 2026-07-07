// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class PlanTile extends StatelessWidget {
  const PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        key: ValueKey('plan-${plan.title}'),
        color: selected ? context.colors.surfaceMuted : context.colors.surface,
        child: InteractiveInk(
          borderRadius: AppRadius.lg,
          onTap: onTap,
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            leading: CircleAvatar(
              backgroundColor:
                  selected ? context.colors.primary : context.colors.surfaceMuted,
              child: Icon(
                plan.icon,
                color: selected ? context.colors.onPrimary : context.colors.textPrimary,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: context.colors.primary),
              ],
            ),
            subtitle: Text(
              plan.recommended
                  ? 'Inapendekezwa - ${plan.subtitle}'
                  : plan.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Text(
              plan.price,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentBenefitsCard extends StatelessWidget {
  const PaymentBenefitsCard();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.smart_toy_outlined, 'Mwalimu AI bila kikomo'),
      (Icons.menu_book_outlined, 'Masomo na nyaraka za premium'),
      (Icons.support_agent, 'Kipaumbele kwa msaada wa mtaalamu'),
    ];

    return Card(
      color: context.colors.surfaceMuted,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration:
                          AppDecorations.pastelPanel(context, context.colors.surface),
                      child: Icon(benefit.$1, color: context.colors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        benefit.$2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({required this.plan, required this.method});

  final PlanOption plan;
  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: context.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${plan.title} kupitia $method',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Text(
            plan.price,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class PaymentStatusScreen extends StatelessWidget {
  const PaymentStatusScreen({
    required this.isSuccess,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final bool isSuccess;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  bool _isPending(BuildContext context) => !isSuccess && onRetry == null;

  Color _surfaceColor(BuildContext context) {
    if (isSuccess) return context.colors.successSurface;
    if (_isPending(context)) return context.colors.surfaceMuted;
    return context.colors.surfacePeach;
  }

  Color _iconColor(BuildContext context) {
    if (isSuccess) return context.colors.success;
    if (_isPending(context)) return context.colors.primary;
    return context.colors.secondary;
  }

  IconData _icon(BuildContext context) {
    if (isSuccess) return Icons.verified_user;
    if (_isPending(context)) return Icons.hourglass_top_rounded;
    return Icons.refresh;
  }

  @override
  Widget build(BuildContext context) {
    final pending = _isPending(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: AppLayout(
          child: Center(
            child: FadeInContent(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Card(
                color: context.colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: _surfaceColor(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _iconColor(context).withValues(alpha: 0.18),
                          ),
                        ),
                        child: pending
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  color: _iconColor(context),
                                ),
                              )
                            : Icon(
                                _icon(context),
                                color: _iconColor(context),
                                size: 48,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: context.colors.muted,
                              height: 1.45,
                            ),
                      ),
                      if (isSuccess || onRetry != null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onRetry ??
                                () {
                                  AppFeedback.success();
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                },
                            icon: Icon(
                              isSuccess
                                  ? Icons.home_outlined
                                  : Icons.refresh,
                            ),
                            label: Text(
                              isSuccess ? 'Rudi Nyumbani' : 'Jaribu Tena',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
