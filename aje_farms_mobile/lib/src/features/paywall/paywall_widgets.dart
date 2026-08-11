// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class AccessBenefitsCard extends StatelessWidget {
  const AccessBenefitsCard();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.smart_toy_outlined, 'Ufikiaji wa Mwalimu AI'),
      (Icons.menu_book_outlined, 'Masomo yaliyo kwenye kifurushi'),
      (Icons.support_agent, 'Njia ya kuwasiliana na mtaalamu'),
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
                      decoration: AppDecorations.pastelPanel(
                          context, context.colors.surface),
                      child: Icon(benefit.$1,
                          color: context.colors.primary, size: 20),
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
