part of '../../app.dart';

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.blue,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -8,
                child: Icon(Icons.eco,
                    size: 96, color: Colors.white.withValues(alpha: 0.48)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Pill(label: '24h Jaribio Lako'),
                  const SizedBox(height: 22),
                  Text('Una changamoto gani leo?',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Pata ushauri wa kitaalamu papo hapo kwa msaada wa AI.'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.search),
                    label: const Text('Eleza Tatizo'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(170, 50),
                      backgroundColor: AppColors.text,
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

class _MiniActionCard extends StatelessWidget {
  const _MiniActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.foreground = AppColors.text,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: foreground == Colors.white
                      ? Colors.white12
                      : Colors.white,
                  child: Icon(icon,
                      color: foreground == Colors.white
                          ? Colors.white
                          : AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: TextStyle(
                        color: foreground, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                      color: foreground.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({required this.course, required this.onTap});

  final DemoCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.peach,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 94,
                  height: 94,
                  child: _NetworkPhoto(url: course.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('SEHEMU YA 4/6',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${(course.progress * 100).round()}%',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: course.progress),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
