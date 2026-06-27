part of '../../app.dart';

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 48,
          height: compact ? 38 : 48,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          'AJE Farms',
          style: TextStyle(
              fontSize: compact ? 18 : 22, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
