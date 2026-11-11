// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final expanded = AppBreakpoints.isExpanded(context);
            final minHeight = constraints.maxHeight - AppSpacing.xxxl;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: AppLayout(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Expanded(child: BrandHeader()),
                            LanguageToggleButton(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Expanded(
                          child: expanded
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(
                                      flex: 3,
                                      child: _OnboardingHeroCard(),
                                    ),
                                    const SizedBox(width: AppSpacing.xxl),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ..._OnboardingActions.build(context),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(
                                        child: _OnboardingHeroCard()),
                                    const SizedBox(height: AppSpacing.xxl),
                                    ..._OnboardingActions.build(context),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingHeroCard extends StatelessWidget {
  const _OnboardingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            context.colors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppElevation.float(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pill(
            label: tr('Mafunzo ya vitendo'),
            color: context.colors.secondary,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: context.colors.onPrimaryFaint,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: context.colors.onPrimaryBorder,
                    ),
                  ),
                  child: const ExcludeSemantics(
                    child: Center(
                      child: BrandMark(
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  tr('Kilimo na Ujasiriamali'),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  tr(
                    'Soma mafunzo, rekodi changamoto za shamba, shiriki na wakulima, na wasiliana na mtaalamu unapohitaji uthibitisho.',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.onPrimarySubtle,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                OnboardingValueRow(
                  icon: Icons.smart_toy_outlined,
                  label: tr('Mwongozo wa kurekodi changamoto za shamba'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingValueRow(
                  icon: Icons.menu_book_outlined,
                  label: tr('Masomo ya vitendo kwa mazao na mifugo'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OnboardingValueRow(
                  icon: Icons.support_agent,
                  label: tr('Msaada wa mtaalamu kupitia WhatsApp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _OnboardingActions {
  static List<Widget> build(BuildContext context) {
    return [
      FilledButton.icon(
        onPressed: () {
          AppFeedback.tap();
          AppNavigator.pushAuth(context);
        },
        icon: const Icon(Icons.login),
        label: Text(tr('Ingia / Jisajili')),
      ),
    ];
  }
}

class OnboardingValueRow extends StatelessWidget {
  const OnboardingValueRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.onPrimary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: accessibleCaption(
              context,
              color: context.colors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
