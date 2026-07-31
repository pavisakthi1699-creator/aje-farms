// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
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
      _isLoading = true;
    });

    final authService = context.dependencies.authService;
    final learningProgressService =
        context.dependencies.learningProgressService;
    final refreshCatalog = context.dependencies.refreshCatalog;
    final appSession = context.session;
    try {
      if (_mode == _AuthMode.signUp) {
        await authService.signUp(email: email, password: password);
        if (!mounted) return;
        setState(() => _isLoading = false);
        showSuccessSnack(
          context,
          'Akaunti imeundwa. Thibitisha barua pepe yako kisha ingia.',
        );
        setState(() => _mode = _AuthMode.signIn);
        return;
      }

      await authService.signIn(email: email, password: password);
      final session = await authService.getSession();
      await appSession.signInWithEmail(session.email, role: session.role);
      await appSession.syncAccountStatusFromAuthSession(session);
      await appSession.syncProfileFromAuthSession(session);
      await refreshCatalog();
      try {
        final completedLessons =
            await learningProgressService.completedLessons();
        await appSession.syncCompletedLessons(completedLessons);
      } on LearningProgressException {
        // Progress sync should not block sign-in.
      }
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
    if (!mounted) return;
    setState(() => _isLoading = false);
    AppNavigator.replaceWithMainShell(context);
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
              if (!isSignUp) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text('Umesahau nenosiri?'),
                  ),
                ),
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
