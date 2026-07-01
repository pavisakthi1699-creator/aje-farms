// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class PaymentBadge extends StatelessWidget {
  const PaymentBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      backgroundColor: Colors.grey.shade50,
    );
  }
}
