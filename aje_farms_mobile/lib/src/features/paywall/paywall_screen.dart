part of '../../app.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const _PaymentStatusScreen(
        isSuccess: false,
        title: 'Inasubiri uthibitisho...',
        body:
            'Tafadhali ingiza namba ya siri kwenye simu yako kuthibitisha malipo.',
      );
    }

    if (_isSuccess) {
      return const _PaymentStatusScreen(
        isSuccess: true,
        title: 'Malipo Yamefanikiwa!',
        body:
            'Akaunti yako imefunguliwa kwa siku 30. Asante kwa kujiunga nasi.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AJE Farms'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Baadaye'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 190,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              image: DecorationImage(
                image: NetworkImage(_demoRepository.featuredCourse.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.42), BlendMode.darken),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Pill(label: 'Kifurushi Kimeisha', color: AppColors.secondary),
                SizedBox(height: 10),
                Text(
                  'Muda wa jaribio umeisha',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lipa kuendelea kupata mafunzo, vitabu na msaada wa AI kwenye kilimo chako.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ..._demoRepository.plans.map((plan) => _PlanTile(plan: plan)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'NJIA ZA KULIPA',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 10,
                    children: [
                      _PaymentBadge(label: 'M-Pesa', color: Colors.red),
                      _PaymentBadge(label: 'Tigo', color: Colors.blue),
                      _PaymentBadge(label: 'Airtel', color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _handlePayment,
                    icon: const Icon(Icons.smartphone),
                    label: const Text('Lipa kwa Mobile Money'),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                          child: Text(
                              'Malipo yako ni salama. Tunalinda taarifa zako zote.')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
