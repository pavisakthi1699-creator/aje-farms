part of '../../app.dart';

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.primaryContainer,
        child: const Icon(Icons.landscape_outlined,
            color: AppColors.primary, size: 44),
      ),
    );
  }
}
