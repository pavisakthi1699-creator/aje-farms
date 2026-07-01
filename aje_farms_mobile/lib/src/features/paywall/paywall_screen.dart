// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => PaywallScreenState();
}

class PaywallScreenState extends State<PaywallScreen> {
  PlanOption? _selectedPlan;
  final _phoneController = TextEditingController(text: '0712 345 678');
  String _paymentMethod = 'M-Pesa';
  bool _isProcessing = false;
  bool _isSuccess = false;
  PlanOption? _processingPlan;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      showSnack(context, 'Weka namba ya simu sahihi kwa malipo.');
      return;
    }
    final plan = _currentPlan(context);
    setState(() {
      _processingPlan = plan;
      _isProcessing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await context.session.activateSubscription(plan.title);
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.dependencies.subscriptionRepository.plans;
    final selectedPlan = _processingPlan ?? _currentPlan(context);

    if (_isProcessing) {
      return PaymentStatusScreen(
        isSuccess: false,
        title: 'Inasubiri uthibitisho...',
        body: 'Tafadhali thibitisha ${selectedPlan.price} kupitia '
            '$_paymentMethod kwa namba ${_phoneController.text}.',
      );
    }

    if (_isSuccess) {
      return PaymentStatusScreen(
        isSuccess: true,
        title: 'Malipo Yamefanikiwa!',
        body: '${selectedPlan.title} imewashwa kupitia $_paymentMethod. '
            'Risiti ya demo imetumwa kwa ${_phoneController.text}.',
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
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkPhoto(
                    url: context.dependencies.learningRepository.featuredCourse
                        .imageUrl),
                Container(color: Colors.black.withValues(alpha: 0.42)),
                const Padding(
                  padding: EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Pill(
                          label: 'Kifurushi Kimeisha',
                          color: AppColors.secondary),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lipa kuendelea kupata mafunzo, vitabu na msaada wa AI kwenye kilimo chako.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          const PaymentBenefitsCard(),
          const SizedBox(height: 24),
          ...plans.map(
            (plan) => PlanTile(
              plan: plan,
              selected: plan == selectedPlan,
              onTap: () => setState(() => _selectedPlan = plan),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MALIPO YA MOBILE MONEY',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final method in ['M-Pesa', 'Tigo', 'Airtel'])
                        ChoiceChip(
                          key: ValueKey('payment-method-$method'),
                          selected: _paymentMethod == method,
                          label: Text(method),
                          onSelected: (_) =>
                              setState(() => _paymentMethod = method),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      PaymentBadge(label: 'M-Pesa', color: Colors.red),
                      PaymentBadge(label: 'Tigo', color: Colors.blue),
                      PaymentBadge(label: 'Airtel', color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Namba ya simu',
                      hintText: '0712 345 678',
                      filled: true,
                      fillColor: AppColors.background,
                      prefixIcon: const Icon(Icons.phone_iphone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PaymentSummaryCard(
                    plan: selectedPlan,
                    method: _paymentMethod,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _handlePayment,
                    icon: const Icon(Icons.smartphone),
                    label: Text('Lipa ${selectedPlan.price}'),
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

  PlanOption _currentPlan(BuildContext context) {
    final plans = context.dependencies.subscriptionRepository.plans;
    return _selectedPlan ??
        plans.firstWhere(
          (plan) => plan.recommended,
          orElse: () => plans.first,
        );
  }
}
