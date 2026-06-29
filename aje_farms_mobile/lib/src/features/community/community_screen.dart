part of '../../app.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'Zote';

  List<CommunityPost> get _filteredPosts {
    if (_selectedFilter == 'Zote') return _demoRepository.posts;
    return _demoRepository.posts
        .where((post) => post.tags.contains(_selectedFilter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;
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
          _CommunitySummaryCard(posts: _demoRepository.posts),
          const SizedBox(height: 16),
          _CommunityFilters(
            selectedFilter: _selectedFilter,
            onSelected: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 18),
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _CommunityPostCard(
                post: post,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CommunityPostDetailScreen(post: post),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({required this.post, super.key});

  final CommunityPost post;

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final _replyController = TextEditingController();
  final List<CommunityReply> _demoReplies = [];

  List<CommunityReply> get _replies =>
      [...widget.post.replies, ..._demoReplies];

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _demoReplies.add(CommunityReply(
        author: 'Wewe',
        body: text,
        time: 'Sasa hivi',
      ));
      _replyController.clear();
    });
    _showSnack(context, 'Jibu limehifadhiwa kwenye demo.');
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Majadiliano'),
        actions: [
          IconButton(
            tooltip: 'Ripoti post',
            onPressed: () =>
                _showSnack(context, 'Ripoti imepokelewa kwenye demo.'),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _CommunityPostCard(post: post, onOpen: () {}),
          const SizedBox(height: 10),
          _DiscussionActionPanel(post: post),
          const SizedBox(height: 22),
          Text('Majibu ya wakulima',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._replies.map((reply) => _CommunityReplyTile(reply: reply)),
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Andika jibu la kusaidia...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                key: const ValueKey('community-send-reply'),
                onPressed: _sendReply,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
