// ignore_for_file: use_key_in_widget_constructors

import 'dart:async';

import "../../ui.dart";
import '../../app/build_flags.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => AuthScreenState();
}

/// Server-side OTP rate limit is one request per phone number per 60s, so the
/// resend affordance stays disabled for the same window.
const Duration _otpResendCooldown = Duration(seconds: 60);

class AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();
  bool _otpSent = false;
  bool _isLoading = false;
  OtpChallenge? _challenge;
  String? _phoneError;
  String? _otpError;
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _otpResendCooldown.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSecondsLeft -= 1);
      if (_resendSecondsLeft <= 0) timer.cancel();
    });
  }

  /// Returns the validation message for the current phone input, or null when
  /// it is acceptable.
  String? _validatePhone(String phone) {
    if (phone.isEmpty) return 'Weka namba yako ya simu.';
    if (phone.length < 9) {
      return 'Namba ya simu inahitaji tarakimu 9 au zaidi.';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Tumia tarakimu tu, bila nafasi au alama.';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    final validationError = _validatePhone(phone);
    if (validationError != null) {
      // Inline beneath the field and focused, rather than a snack bar that
      // disappears and leaves the user guessing which input was wrong.
      setState(() => _phoneError = validationError);
      _phoneFocus.requestFocus();
      return;
    }
    setState(() {
      _phoneError = null;
      _isLoading = true;
    });
    try {
      final challenge =
          await context.dependencies.authService.requestOtp('+255 $phone');
      if (!mounted) return;
      final isResend = _otpSent;
      setState(() {
        _challenge = challenge;
        _otpSent = true;
        _otpError = null;
        _isLoading = false;
      });
      _startResendCooldown();
      // Move focus to the code field so the user can type (or let the platform
      // autofill the SMS code) without hunting for the next input.
      if (!isResend) _otpFocus.requestFocus();
      showSuccessSnack(context, challenge.message);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: _sendOtp,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnack(
        context,
        'Imeshindikana kutuma OTP. Angalia mtandao wako.',
        actionLabel: 'Jaribu tena',
        onAction: _sendOtp,
      );
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
      setState(
        () => _otpError = 'Weka OTP uliyoipokea kwa SMS ili kuendelea.',
      );
      _otpFocus.requestFocus();
      return;
    }
    if (requireOtp) setState(() => _otpError = null);
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
        setState(() {
          _isLoading = false;
          _otpError = error.message;
        });
        _otpFocus.requestFocus();
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _otpError = 'Imeshindikana kuthibitisha OTP. Jaribu tena.';
        });
        _otpFocus.requestFocus();
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
      // AutofillGroup is required for `autofillHints` to be honoured; without
      // it the platform never offers the saved number or the SMS code.
      body: AutofillGroup(
        child: AppLayout(
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
                focusNode: _phoneFocus,
                labelText: 'Namba ya simu',
                helperText: 'Mfano: 712345678',
                prefixText: '+255 ',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                errorText: _phoneError,
                // Clear the error as soon as the user starts correcting it.
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                onSubmitted: (_) => _sendOtp(),
              ),
              if (_otpSent) ...[
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _otpController,
                  focusNode: _otpFocus,
                  labelText: 'OTP',
                  helperText: 'Weka tarakimu 6 ulizopokea',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  // Lets Android/iOS auto-fill the code straight from the SMS.
                  autofillHints: const [AutofillHints.oneTimeCode],
                  errorText: _otpError,
                  onChanged: (_) {
                    if (_otpError != null) setState(() => _otpError = null);
                  },
                  onSubmitted: (_) => _continueToApp(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isLoading || _resendSecondsLeft > 0
                        ? null
                        : () {
                            AppFeedback.tap();
                            _sendOtp();
                          },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      _resendSecondsLeft > 0
                          ? 'Tuma tena baada ya sekunde $_resendSecondsLeft'
                          : 'Tuma OTP tena',
                    ),
                  ),
                ),
                if (kInternalBuild && _challenge?.debugOtp != null) ...[
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
      ),
    );
  }
}
