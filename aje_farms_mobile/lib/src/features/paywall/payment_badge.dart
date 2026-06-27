part of '../../app.dart';

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label, required this.color});

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
