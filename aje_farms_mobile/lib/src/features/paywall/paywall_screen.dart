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
  bool _isFailure = false;
  bool _phonePrefilled = false;
  String? _statusTitle;
  String? _statusBody;
  PlanOption? _processingPlan;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phonePrefilled) return;
    final phoneNumber = context.session.phoneNumber;
    if (phoneNumber != null && context.session.isSignedIn) {
      _phoneController.text = phoneNumber.startsWith('+255')
          ? '0${phoneNumber.substring(4)}'
          : phoneNumber;
    }
    _phonePrefilled = true;
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
      _isFailure = false;
      _statusTitle = 'Inasubiri uthibitisho...';
      _statusBody = 'Tafadhali thibitisha ${plan.price} kupitia '
          '$_paymentMethod kwa namba $phone.';
    });
    final paymentService = context.dependencies.paymentService;
    final authService = context.dependencies.authService;
    final appSession = context.session;
    PaymentTransaction transaction;
    try {
      transaction = await paymentService.startCheckout(
        planTitle: plan.title,
        price: plan.price,
        method: _paymentMethod,
        phoneNumber: phone,
      );
    } on PaymentException catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusTitle = null;
        _statusBody = null;
      });
      showSnack(context, error.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusTitle = null;
        _statusBody = null;
      });
      showSnack(context, 'Malipo yameshindikana. Jaribu tena.');
      return;
    }

    if (transaction.isPending) {
      setState(() {
        _statusBody = transaction.checkoutInstructions ?? transaction.message;
      });
      try {
        transaction = await _waitForPaymentConfirmation(
          paymentService,
          transaction,
        );
      } on PaymentException catch (error) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _isFailure = true;
          _statusTitle = 'Malipo hayajakamilika';
          _statusBody = error.message;
        });
        return;
      }
    }

    if (!mounted) return;
    if (!transaction.isPaid) {
      setState(() {
        _isProcessing = false;
        _isFailure = true;
        _statusTitle = transaction.isPending
            ? 'Bado tunasubiri uthibitisho'
            : 'Malipo hayajakamilika';
        _statusBody = transaction.message;
      });
      return;
    }

    final signedInPhone = appSession.phoneNumber;
    final paymentPhone = transaction.phoneNumber;
    if (signedInPhone != null &&
        !appSession.state.isGuest &&
        signedInPhone == paymentPhone) {
      try {
        final session = await authService.getSession(signedInPhone);
        await appSession.syncSubscriptionFromAuthSession(session);
        await appSession.syncProfileFromAuthSession(session);
      } on AuthException {
        await appSession.activateSubscription(
          transaction.subscriptionPlan ?? transaction.planTitle,
          startedAt: transaction.subscriptionStartedAt,
        );
      }
    } else {
      await appSession.activateSubscription(
        transaction.subscriptionPlan ?? transaction.planTitle,
        startedAt: transaction.subscriptionStartedAt,
      );
    }
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _isFailure = false;
      _statusTitle = 'Malipo Yamefanikiwa!';
      _statusBody =
          '${transaction.planTitle} imewashwa kupitia ${transaction.method}. '
          'Risiti ${transaction.receiptNumber ?? transaction.id} imetumwa kwa ${transaction.phoneNumber}.';
    });
  }

  Future<PaymentTransaction> _waitForPaymentConfirmation(
    PaymentService paymentService,
    PaymentTransaction transaction,
  ) async {
    var current = transaction;
    for (var attempt = 0; attempt < 8; attempt += 1) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return current;
      current = await paymentService.getStatus(current.id);
      if (!current.isPending) return current;
      if (mounted) {
        setState(() {
          _statusBody =
              'Bado tunasubiri uthibitisho wa ${current.method}. Jaribio ${attempt + 1}/8.';
        });
      }
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.dependencies.subscriptionRepository.plans;
    final selectedPlan = _processingPlan ?? _currentPlan(context);

    if (_isProcessing) {
      return PaymentStatusScreen(
        isSuccess: false,
        title: _statusTitle ?? 'Inasubiri uthibitisho...',
        body: _statusBody ??
            'Tafadhali thibitisha ${selectedPlan.price} kupitia '
                '$_paymentMethod kwa namba ${_phoneController.text}.',
      );
    }

    if (_isSuccess) {
      return PaymentStatusScreen(
        isSuccess: true,
        title: _statusTitle ?? 'Malipo Yamefanikiwa!',
        body: _statusBody ??
            '${selectedPlan.title} imewashwa kupitia $_paymentMethod.',
      );
    }

    if (_isFailure) {
      return PaymentStatusScreen(
        isSuccess: false,
        title: _statusTitle ?? 'Malipo hayajakamilika',
        body: _statusBody ?? 'Jaribu tena au tumia njia nyingine ya malipo.',
        onRetry: () => setState(() {
          _isFailure = false;
          _statusTitle = null;
          _statusBody = null;
          _processingPlan = null;
        }),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vifurushi'),
      ),
      body: AppLayoutScroll(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        header: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: _PaywallHeroBanner(
            imageUrl: context
                    .dependencies.learningRepository.featuredCourse?.imageUrl ??
                'assets/images/farm-field.jpg',
          ),
        ),
        bodyPadding: const EdgeInsets.all(AppSpacing.xl),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lipa kuendelea kupata mafunzo, vitabu na msaada wa AI kwenye kilimo chako.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const PaymentBenefitsCard(),
            const SizedBox(height: AppSpacing.xxl),
            ...plans.map(
              (plan) => PlanTile(
                plan: plan,
                selected: plan == selectedPlan,
                onTap: () => setState(() => _selectedPlan = plan),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MALIPO YA MOBILE MONEY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final method in ['M-Pesa', 'Tigo', 'Airtel'])
                          ChoiceChip(
                            key: ValueKey('payment-method-$method'),
                            selected: _paymentMethod == method,
                            label: Text(method),
                            onSelected: (_) {
                              AppFeedback.selection();
                              setState(() => _paymentMethod = method);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        PaymentBadge(label: 'M-Pesa'),
                        PaymentBadge(label: 'Tigo'),
                        PaymentBadge(label: 'Airtel'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Namba ya simu',
                        hintText: '0712 345 678',
                        prefixIcon: Icon(Icons.phone_iphone),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PaymentSummaryCard(
                      plan: selectedPlan,
                      method: _paymentMethod,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () {
                        AppFeedback.tap();
                        _handlePayment();
                      },
                      icon: const Icon(Icons.smartphone),
                      label: Text('Lipa ${selectedPlan.price}'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: context.colors.success,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'Thibitisha jina la mpokeaji na kiasi kwenye simu yako kabla ya kukubali malipo.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _PaywallHeroBanner extends StatelessWidget {
  const _PaywallHeroBanner({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppElevation.float(context),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(url: imageUrl),
          Container(color: context.colors.charcoal.withValues(alpha: 0.42)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Pill(
                  label: 'Kifurushi Kimeisha',
                  color: context.colors.secondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Muda wa jaribio umeisha',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.colors.onPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
