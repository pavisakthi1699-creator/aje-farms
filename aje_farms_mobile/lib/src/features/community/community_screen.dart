// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'Zote';

  List<CommunityPost> _filteredPosts(BuildContext context) {
    final session = context.session;
    final posts = [
      ...session.state.localPosts,
      ...context.dependencies.communityRepository.posts,
    ];
    if (_selectedFilter == 'Zote') return posts;
    return posts.where((post) => post.tags.contains(_selectedFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPosts = [
      ...context.session.state.localPosts,
      ...context.dependencies.communityRepository.posts,
    ];
    final posts = _filteredPosts(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Jamii ya Wakulima')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateCommunityPostScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CommunitySummaryCard(posts: allPosts),
          const SizedBox(height: 16),
          CommunityFilters(
            selectedFilter: _selectedFilter,
            onSelected: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 18),
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: CommunityPostCard(
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
      CommunityPostDetailScreenState();
}

class CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final _replyController = TextEditingController();

  List<CommunityReply> _replies(BuildContext context) => [
        ...widget.post.replies,
        ...context.session.repliesFor(_postId),
      ];

  String get _postId => widget.post.id.isEmpty
      ? '${widget.post.author}-${widget.post.content}'
      : widget.post.id;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    await context.session.addCommunityReply(_postId, text);
    _replyController.clear();
    if (!mounted) return;
    showSnack(context, 'Jibu limehifadhiwa.');
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final reported = context.session.isPostReported(_postId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Majadiliano'),
        actions: [
          IconButton(
            tooltip: reported ? 'Post imeripotiwa' : 'Ripoti post',
            onPressed: reported
                ? null
                : () async {
                    await context.session.reportCommunityPost(_postId);
                    if (!context.mounted) return;
                    showSnack(context, 'Ripoti imepokelewa.');
                  },
            icon: Icon(reported ? Icons.flag : Icons.flag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CommunityPostCard(post: post, onOpen: () {}),
          const SizedBox(height: 10),
          DiscussionActionPanel(post: post),
          const SizedBox(height: 22),
          Text('Majibu ya wakulima',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._replies(context).map((reply) => CommunityReplyTile(reply: reply)),
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

class CreateCommunityPostScreen extends StatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  State<CreateCommunityPostScreen> createState() =>
      CreateCommunityPostScreenState();
}

class CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final Set<String> _tags = {'Magonjwa'};
  bool _initializedLocation = false;

  static const _availableTags = [
    'Magonjwa',
    'Wadudu',
    'Mbolea',
    'Maji',
    'Masoko',
    'Kuku',
    'Nyanya',
    'Pasheni',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedLocation) return;
    _locationController.text = context.session.state.preferredLocation ?? '';
    _initializedLocation = true;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();
    if (content.length < 12) {
      showSnack(context, 'Andika maelezo ya kutosha kuhusu changamoto.');
      return;
    }
    if (location.isEmpty) {
      showSnack(context, 'Weka eneo lako ili wakulima wakuelewe vizuri.');
      return;
    }
    final session = context.session;
    await session.setPreferredLocation(location);
    await session.addCommunityPost(
      content: content,
      location: location,
      tags: _tags.toList()..sort(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(context, 'Post imetumwa kwenye jamii.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuma Swali')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _contentController,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: 'Swali au changamoto',
              hintText: 'Mfano: Majani ya nyanya yana madoa ya njano...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Eneo',
              hintText: 'Mfano: Morogoro',
              prefixIcon: const Icon(Icons.place_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Chagua mada', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _availableTags)
                FilterChip(
                  selected: _tags.contains(tag),
                  label: Text(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tags.add(tag);
                      } else if (_tags.length > 1) {
                        _tags.remove(tag);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text('Tuma kwenye Jamii'),
          ),
        ],
      ),
    );
  }
}
