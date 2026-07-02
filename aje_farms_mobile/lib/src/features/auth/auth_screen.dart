// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  OtpChallenge? _challenge;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      showSnack(context, 'Weka namba ya simu yenye tarakimu 9 au zaidi.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final challenge =
          await context.dependencies.authService.requestOtp('+255 $phone');
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _otpSent = true;
        _isLoading = false;
      });
      showSnack(context, challenge.message);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showSnack(context, 'Imeshindikana kutuma OTP. Jaribu tena.');
    }
  }

  Future<void> _continueToApp({bool requireOtp = true}) async {
    final phone = '+255 ${_phoneController.text.trim()}';
    final challenge = _challenge;
    if (requireOtp && (challenge == null || !_otpSent)) {
      await _sendOtp();
      return;
    }
    if (requireOtp && _otpController.text.trim().length < 4) {
      showSnack(context, 'Weka OTP ya mfano ili kuendelea.');
      return;
    }
    final authService = context.dependencies.authService;
    final appSession = context.session;
    setState(() => _isLoading = true);
    if (requireOtp) {
      try {
        final session = await authService.verifyOtp(
          phoneNumber: phone,
          otp: _otpController.text.trim(),
          challengeId: challenge!.challengeId,
        );
        await appSession.signInWithPhone(session.phoneNumber);
      } on AuthException catch (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showSnack(context, error.message);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showSnack(context, 'Imeshindikana kuthibitisha OTP.');
        return;
      }
    } else {
      await appSession.startAsGuest();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingia / Jisajili')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandHeader(),
          const SizedBox(height: 28),
          const Text(
            'Karibu tena',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Tumia namba yako ya simu kupata mafunzo, kuhifadhi maendeleo yako, na kufungua msaada wa premium.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.mint,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tutahifadhi kikao chako kwenye kifaa hiki. Kwa sasa OTP ni ya majaribio mpaka huduma ya SMS iunganishwe.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendOtp(),
            decoration: InputDecoration(
              labelText: 'Namba ya simu',
              helperText: 'Mfano: 712345678',
              prefixText: '+255 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continueToApp(),
              decoration: InputDecoration(
                labelText: 'OTP',
                helperText: 'Weka tarakimu 4 ulizopokea',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (_challenge?.debugOtp != null) ...[
              const SizedBox(height: 8),
              Text(
                'OTP ya majaribio: ${_challenge!.debugOtp}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed:
                _isLoading ? null : (_otpSent ? _continueToApp : _sendOtp),
            icon: _isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_otpSent ? Icons.login : Icons.sms_outlined),
            label: Text(_otpSent ? 'Endelea kwenye App' : 'Tuma OTP'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _continueToApp(requireOtp: false),
            child: const Text('Endelea kama mgeni'),
          ),
        ],
      ),
    );
  }
}
