// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({required this.url});

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
