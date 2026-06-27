part of '../../app.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingia')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Authentication',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Hapa tutaunganisha phone OTP, email login, na role-based access kupitia Supabase au Firebase.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Namba ya simu',
              prefixText: '+255 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _showSnack(context, 'OTP ya mfano imetumwa.'),
            child: const Text('Tuma OTP'),
          ),
        ],
      ),
    );
  }
}
