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
      setState(() => _error = 'Nenosiri linahitajika kuwa na angalau tarakimu 6.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Nenosiri halijalingana.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await context.dependencies.authService.updatePassword(password);
      if (!mounted) return;
      showSuccessSnack(context, 'Nenosiri lako limebadilishwa. Sasa unaweza kuingia.');
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Kiungo hiki kimeisha muda au si sahihi. Omba kiungo kipya.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Weka nenosiri jipya')),
    body: AppLayout(
      child: ListView(padding: const EdgeInsets.all(AppSpacing.xxl), children: [
        const BrandHeader(),
        const SizedBox(height: AppSpacing.xxl),
        Text('Unda nenosiri jipya', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text('Weka nenosiri jipya kwa akaunti yako ya AJE Farms.'),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(controller: _passwordController, labelText: 'Nenosiri jipya', obscureText: true, autofillHints: const [AutofillHints.newPassword], errorText: _error),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: _confirmController, labelText: 'Rudia nenosiri', obscureText: true, textInputAction: TextInputAction.done, autofillHints: const [AutofillHints.newPassword], onSubmitted: (_) => _save()),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Hifadhi nenosiri')),
      ]),
    ),
  );
}
