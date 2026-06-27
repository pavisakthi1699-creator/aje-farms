part of '../../app.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.actionIcon, required this.onAction});

  final String title;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        IconButton.filledTonal(onPressed: onAction, icon: Icon(actionIcon)),
      ],
    );
  }
}
