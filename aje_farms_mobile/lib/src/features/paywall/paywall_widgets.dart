part of '../../app.dart';

class _PlanTile extends StatelessWidget {
  const _PlanTile({
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: selected ? AppColors.mint : Colors.white,
        child: InkWell(
          key: ValueKey('plan-${plan.title}'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: CircleAvatar(
              backgroundColor:
                  selected ? AppColors.primary : Colors.grey.shade100,
              child: Icon(plan.icon,
                  color: selected ? Colors.white : AppColors.text),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(plan.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
            subtitle: Text(plan.recommended
                ? 'Inapendekezwa - ${plan.subtitle}'
                : plan.subtitle),
            trailing: Text(
              plan.price,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentBenefitsCard extends StatelessWidget {
  const _PaymentBenefitsCard();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.smart_toy_outlined, 'Mwalimu AI bila kikomo'),
      (Icons.menu_book_outlined, 'Masomo na nyaraka za premium'),
      (Icons.support_agent, 'Kipaumbele kwa msaada wa mtaalamu'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(benefit.$1, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(benefit.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.plan, required this.method});

  final PlanOption plan;
  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${plan.title} kupitia $method',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            plan.price,
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusScreen extends StatelessWidget {
  const _PaymentStatusScreen({
    required this.isSuccess,
    required this.title,
    required this.body,
  });

  final bool isSuccess;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSuccess)
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFDFF6E7),
                  child:
                      Icon(Icons.verified_user, color: Colors.green, size: 48),
                )
              else
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(strokeWidth: 5),
                ),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (isSuccess) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Rudi Nyumbani'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
