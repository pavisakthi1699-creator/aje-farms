// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class CommunityTeaser extends StatelessWidget {
  const CommunityTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleTappable(
      label: 'Jiunge na Jamii',
      hint: 'Wakulima 1,200+ wanajadili pasheni, nyanya na kuku.',
      onTap: onTap,
      child: Card(
        child: InteractiveInk(
          borderRadius: AppRadius.lg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: AppA11y.minTouchTarget,
                  height: AppA11y.minTouchTarget,
                  decoration:
                      AppDecorations.pastelPanel(context, context.colors.surfaceMuted),
                  child: Icon(
                    Icons.groups_outlined,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jiunge na Jamii',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Wakulima 1,200+ wanajadili pasheni, nyanya na kuku.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(Icons.chevron_right, color: context.colors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
