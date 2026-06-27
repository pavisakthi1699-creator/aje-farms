part of '../../app.dart';

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final PlanOption plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: plan.recommended ? AppColors.mint : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: CircleAvatar(
            backgroundColor:
                plan.recommended ? AppColors.primary : Colors.grey.shade100,
            child: Icon(plan.icon,
                color: plan.recommended ? Colors.white : AppColors.text),
          ),
          title: Text(plan.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
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
            ],
          ),
        ),
      ),
    );
  }
}
