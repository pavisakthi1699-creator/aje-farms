part of '../../app.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jamii ya Wakulima')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showSnack(context, 'Kutuma post kutaunganishwa na backend.'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _CommunityFilters(),
          const SizedBox(height: 18),
          ...communityPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _CommunityPostCard(post: post),
            ),
          ),
        ],
      ),
    );
  }
}
