// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class PaymentBadge extends StatelessWidget {
  const PaymentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'M-Pesa' => context.colors.mpesa,
      'Tigo' => context.colors.tigo,
      'Airtel' => context.colors.airtel,
      _ => context.colors.primary,
    };
    return Chip(
      avatar:
          Icon(Icons.account_balance_wallet_outlined, color: color, size: 16),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.32)),
    );
  }
}
