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
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 34),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body),
              const SizedBox(height: 18),
              Text(
                action,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
