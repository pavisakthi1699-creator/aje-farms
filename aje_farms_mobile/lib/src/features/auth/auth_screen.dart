// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/foundation.dart';

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
      showSnack(context, 'Weka OTP uliyoipokea ili kuendelea.');
      return;
    }
    final authService = context.dependencies.authService;
    final learningProgressService =
        context.dependencies.learningProgressService;
    final appSession = context.session;
    setState(() => _isLoading = true);
    if (requireOtp) {
      try {
        final session = await authService.verifyOtp(
          phoneNumber: phone,
          otp: _otpController.text.trim(),
          challengeId: challenge!.challengeId,
        );
        await appSession.signInWithPhone(
          session.phoneNumber,
          sessionToken: session.sessionToken,
          role: session.role,
        );
        await appSession.syncSubscriptionFromAuthSession(session);
        await appSession.syncRoleFromAuthSession(session);
        await appSession.syncProfileFromAuthSession(session);
        try {
          final completedLessons =
              await learningProgressService.completedLessons(
            session.phoneNumber,
          );
          await appSession.syncCompletedLessons(completedLessons);
        } on LearningProgressException {
          // Progress sync should not block sign-in.
        }
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
    AppNavigator.replaceWithMainShell(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingia / Jisajili')),
      body: AppLayout(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            const BrandHeader(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Karibu tena',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tumia namba yako ya simu kupata mafunzo, kuhifadhi maendeleo yako, na kufungua msaada wa premium.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Card(
              color: context.colors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: AppDecorations.pastelPanel(
                          context, context.colors.surface),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: context.colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Tutahifadhi kikao chako kwenye kifaa hiki baada ya kuthibitisha namba yako kwa OTP.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              controller: _phoneController,
              labelText: 'Namba ya simu',
              helperText: 'Mfano: 712345678',
              prefixText: '+255 ',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendOtp(),
            ),
            if (_otpSent) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _otpController,
                labelText: 'OTP',
                helperText: 'Weka tarakimu 6 ulizopokea',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continueToApp(),
              ),
              if (kDebugMode && _challenge?.debugOtp != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'OTP ya majaribio: ${_challenge!.debugOtp}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      AppFeedback.tap();
                      if (_otpSent) {
                        _continueToApp();
                      } else {
                        _sendOtp();
                      }
                    },
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_otpSent ? Icons.login : Icons.sms_outlined),
              label: Text(_otpSent ? 'Endelea' : 'Tuma OTP'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      AppFeedback.tap();
                      _continueToApp(requireOtp: false);
                    },
              child: const Text('Endelea kama mgeni'),
            ),
          ],
        ),
      ),
    );
  }
}
