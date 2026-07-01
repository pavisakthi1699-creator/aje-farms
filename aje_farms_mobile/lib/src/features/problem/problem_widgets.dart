// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ProblemCategoryTile extends StatelessWidget {
  const ProblemCategoryTile({
    required this.category,
    required this.onTap,
    super.key,
  });

  final ProblemCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: category.color.withValues(alpha: 0.12),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(category.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  category.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.25,
                      ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final example in category.examples)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                          color: category.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnknownProblemTile extends StatelessWidget {
  const UnknownProblemTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        child: Icon(Icons.help_outline, color: AppColors.primary),
      ),
      title: const Text('Sijui tatizo',
          style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: const Text('Mwalimu AI itakusaidia kutambua'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class TrendingTopics extends StatelessWidget {
  const TrendingTopics();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.water_drop, 'Maji', Colors.blue),
      (Icons.bug_report, 'Wadudu', Colors.red),
      (Icons.eco, 'Mbolea', AppColors.primary),
      (Icons.trending_up, 'Soko', AppColors.secondary),
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            width: 96,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$1, color: item.$3),
                const SizedBox(height: 10),
                Text(item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }
}
