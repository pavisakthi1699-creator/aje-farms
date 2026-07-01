// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class ExpertPanel extends StatelessWidget {
  const ExpertPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFE8F8EE),
              child: Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
            ),
            const SizedBox(height: 12),
            Text(
              'Ongea na Mtaalamu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Pata ushauri binafsi kupitia WhatsApp yetu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
              child: const Text('Tuma Ujumbe WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
