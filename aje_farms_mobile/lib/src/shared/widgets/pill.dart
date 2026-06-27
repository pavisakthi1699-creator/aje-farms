part of '../../app.dart';

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color = Colors.white});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.82 : 1),
          borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: dark ? AppColors.text : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
