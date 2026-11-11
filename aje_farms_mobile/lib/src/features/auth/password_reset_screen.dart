import '../../ui.dart';
import '../../app/app_routes.dart';

/// Opened by the Supabase recovery link (`ajefarms://login-callback`).
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(
        () => _error = tr('Nenosiri linahitajika kuwa na angalau tarakimu 6.'),
      );
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = tr('Nenosiri halijalingana.'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.dependencies.authService.updatePassword(password);
      if (!mounted) return;
      showSuccessSnack(
        context,
        tr('Nenosiri lako limebadilishwa. Sasa unaweza kuingia.'),
      );
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = tr(error.message));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = tr(
            'Kiungo hiki kimeisha muda au si sahihi. Omba kiungo kipya.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr('Weka nenosiri jipya'))),
        body: AppLayout(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              const BrandHeader(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                tr('Unda nenosiri jipya'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                tr(
                  'Weka nenosiri jipya kwa akaunti yako ya Chuo Kikuu Cha Mtaani.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _passwordController,
                labelText: tr('Nenosiri jipya'),
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                enableIMEPersonalizedLearning: false,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? tr('Onyesha nenosiri jipya')
                      : tr('Ficha nenosiri jipya'),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                autofillHints: const [AutofillHints.newPassword],
                errorText: _error,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _confirmController,
                labelText: tr('Rudia nenosiri'),
                obscureText: _obscureConfirmation,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                enableIMEPersonalizedLearning: false,
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmation
                      ? tr('Onyesha nenosiri lililorudiwa')
                      : tr('Ficha nenosiri lililorudiwa'),
                  onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation),
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : Text(tr('Hifadhi nenosiri')),
              ),
            ],
          ),
        ),
      );
}
