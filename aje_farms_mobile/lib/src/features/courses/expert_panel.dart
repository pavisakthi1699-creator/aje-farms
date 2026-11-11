// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ExpertPanel extends StatelessWidget {
  const ExpertPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.whatsappSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.colors.whatsapp.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: context.colors.whatsapp,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              tr('Ongea na Mtaalamu'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tr('Pata ushauri binafsi kupitia WhatsApp yetu.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                AppFeedback.tap();
                onTap();
              },
              icon: const Icon(Icons.chat),
              label: Text(tr('Tuma Ujumbe WhatsApp')),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.whatsapp,
                foregroundColor: context.colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
