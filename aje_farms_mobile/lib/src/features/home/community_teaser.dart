part of '../../app.dart';

class _CommunityTeaser extends StatelessWidget {
  const _CommunityTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.blue,
          child: Icon(Icons.groups_outlined, color: Colors.blue),
        ),
        title: const Text('Jiunge na Jamii',
            style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle:
            const Text('Wakulima 1,200+ wanajadili pasheni, nyanya na kuku.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
