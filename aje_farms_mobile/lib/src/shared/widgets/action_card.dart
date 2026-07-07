// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleTappable(
      label: title,
      hint: '$body. $action',
      onTap: onTap,
      child: Card(
        color: color,
        child: InteractiveInk(
          borderRadius: AppRadius.xl,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppA11y.minTouchTarget,
                  height: AppA11y.minTouchTarget,
                  decoration: AppDecorations.circleIconButton(context),
                  child: Icon(icon, color: context.colors.primary, size: 24),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  action,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
