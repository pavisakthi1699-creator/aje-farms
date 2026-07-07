// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.primary,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InteractiveInk(
          borderRadius: AppRadius.lg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      AppDecorations.pastelPanel(
                        context,
                        color.withValues(alpha: 0.12),
                      ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.colors.muted,
                              ),
                        ),
                      ],
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
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppSpacing.lg + 44 + AppSpacing.md,
            endIndent: AppSpacing.lg,
          ),
      ],
    );
  }
}
