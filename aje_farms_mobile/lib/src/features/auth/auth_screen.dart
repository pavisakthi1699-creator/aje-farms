// ignore_for_file: use_key_in_widget_constructors

import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import '../../app/build_flags.dart';
import '../../ui.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  _AuthMode _mode = _AuthMode.signIn;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _termsError;
  bool _acceptedTerms = false;
  String? _pendingConfirmationEmail;
  DateTime? _resendAvailableAt;
  Timer? _resendTimer;

  int get _resendSecondsRemaining {
    final availableAt = _resendAvailableAt;
    if (availableAt == null) return 0;
    final seconds = availableAt.difference(DateTime.now()).inSeconds + 1;
    return seconds > 0 ? seconds : 0;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendAvailableAt = DateTime.now().add(const Duration(seconds: 60));
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining == 0) {
        timer.cancel();
        setState(() => _resendAvailableAt = null);
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _completeAuthenticatedSession() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final dependencies = context.dependencies;
    final appSession = context.session;
    try {
      final authService = dependencies.authService;
      final session = await authService.getSession();
      await appSession.signInWithEmail(session.email, role: session.role);
      await appSession.syncAccountStatusFromAuthSession(session);
      await appSession.syncProfileFromAuthSession(session);
      await dependencies.refreshCatalog();
      try {
        final completedLessons =
            await dependencies.learningProgressService.completedLessons();
        await appSession.syncCompletedLessons(completedLessons);
      } on LearningProgressException {
        // Progress sync should not block sign-in.
      }
      if (!mounted) return;
      AppNavigator.replaceWithMainShell(context);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnack(context, 'Imeshindikana kuingia. Angalia mtandao wako.');
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _pendingConfirmationEmail ?? _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      _emailFocus.requestFocus();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.dependencies.authService.resendSignUpConfirmation(email);
      if (!mounted) return;
      _startResendCooldown();
      showSuccessSnack(
        context,
        'Barua mpya ya uthibitisho imetumwa. Angalia inbox na spam.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Imeshindikana kutuma barua. Jaribu tena.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Weka barua pepe yako.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Weka barua pepe sahihi.';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Weka nenosiri lako.';
    if (password.length < 6) {
      return 'Nenosiri linahitajika kuwa na angalau tarakimu 6.';
    }
    return null;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);
    final termsError = _mode == _AuthMode.signUp && !_acceptedTerms
        ? 'Kubali Masharti na Mwongozo wa Jamii ili kujisajili.'
        : null;
    if (emailError != null || passwordError != null || termsError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _termsError = termsError;
      });
      if (emailError != null) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }
    setState(() {
      _emailError = null;
      _passwordError = null;
      _termsError = null;
      _isLoading = true;
    });

    final authService = context.dependencies.authService;
    try {
      if (_mode == _AuthMode.signUp) {
        final result =
            await authService.signUp(email: email, password: password);
        if (!mounted) return;
        if (!result.emailConfirmationRequired) {
          setState(() => _isLoading = false);
          await _completeAuthenticatedSession();
          return;
        }
        setState(() => _isLoading = false);
        _pendingConfirmationEmail = email;
        _startResendCooldown();
        showSuccessSnack(
          context,
          'Kama hii ni akaunti mpya, barua ya uthibitisho imetumwa. Thibitisha kisha ingia.',
        );
        setState(() => _mode = _AuthMode.signIn);
        return;
      }

      await authService.signIn(email: email, password: password);
      setState(() => _isLoading = false);
      await _completeAuthenticatedSession();
      return;
    } on AuthEmailConfirmationRequiredException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _pendingConfirmationEmail = email;
        _mode = _AuthMode.signIn;
      });
      showErrorSnack(context, error.message);
      return;
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnack(context, error.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnack(
        context,
        _mode == _AuthMode.signUp
            ? 'Imeshindikana kujisajili. Angalia mtandao wako.'
            : 'Imeshindikana kuingia. Angalia mtandao wako.',
      );
      return;
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      _emailFocus.requestFocus();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.dependencies.authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      showSuccessSnack(
        context,
        'Tumeuma barua pepe yenye maelekezo ya kubadilisha nenosiri.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Imeshindikana kutuma barua pepe. Angalia mtandao wako.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == _AuthMode.signUp;
    return Scaffold(
      appBar: AppBar(title: const Text('Ingia / Jisajili')),
      body: AutofillGroup(
        child: AppLayout(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              const BrandHeader(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                isSignUp ? 'Fungua akaunti mpya' : 'Karibu tena',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tumia barua pepe na nenosiri kupata mafunzo, kuhifadhi maendeleo yako, na kufungua msaada wa premium.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(value: _AuthMode.signIn, label: Text('Ingia')),
                  ButtonSegment(
                    value: _AuthMode.signUp,
                    label: Text('Jisajili'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _isLoading
                    ? null
                    : (selection) {
                        AppFeedback.selection();
                        setState(() {
                          _mode = selection.first;
                          _emailError = null;
                          _passwordError = null;
                          _termsError = null;
                        });
                      },
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                labelText: 'Barua pepe',
                helperText: 'Mfano: jina@barua.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                labelText: 'Nenosiri',
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: [
                  isSignUp ? AutofillHints.newPassword : AutofillHints.password,
                ],
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
                onSubmitted: (_) => _submit(),
              ),
              if (isSignUp) ...[
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _acceptedTerms,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Ninakubali Masharti ya Matumizi na Mwongozo wa Jamii',
                  ),
                  subtitle: _termsError == null
                      ? null
                      : Text(
                          _termsError!,
                          style: TextStyle(color: context.colors.error),
                        ),
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() {
                            _acceptedTerms = value ?? false;
                            if (_acceptedTerms) _termsError = null;
                          }),
                ),
                if (privacyPolicyUrl.isNotEmpty)
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: () => _openAuthPolicy('/terms'),
                        child: const Text('Soma Masharti'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openAuthPolicy('/community-guidelines'),
                        child: const Text('Mwongozo wa Jamii'),
                      ),
                      TextButton(
                        onPressed: () => _openAuthPolicy('/privacy'),
                        child: const Text('Sera ya Faragha'),
                      ),
                    ],
                  ),
              ],
              if (!isSignUp) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text('Umesahau nenosiri?'),
                  ),
                ),
                if (_pendingConfirmationEmail != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Barua pepe bado haijathibitishwa',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Fungua kiungo tulichotuma kwa $_pendingConfirmationEmail. Kama hakijafika, angalia spam au utume tena.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: _isLoading || _resendSecondsRemaining > 0
                                ? null
                                : _resendConfirmation,
                            icon: const Icon(Icons.mark_email_unread_outlined),
                            label: Text(
                              _resendSecondsRemaining > 0
                                  ? 'Tuma tena baada ya sekunde $_resendSecondsRemaining'
                                  : 'Tuma tena barua ya uthibitisho',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        AppFeedback.tap();
                        _submit();
                      },
                icon: _isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isSignUp ? Icons.person_add_outlined : Icons.login),
                label: Text(isSignUp ? 'Jisajili Sasa' : 'Ingia Sasa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openAuthPolicy(String path) async {
  final base = Uri.tryParse(privacyPolicyUrl);
  if (base == null) return;
  await launchUrl(base.resolve(path), mode: LaunchMode.externalApplication);
}
