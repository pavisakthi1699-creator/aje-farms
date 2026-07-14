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

  Future<void> _handleRefresh() async {
    await context.dependencies.refreshCatalog();
    if (!mounted) return;
    showSnack(context, 'Jamii imesasishwa.');
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = context.dependencies;
    final refreshListenable =
        dependencies.refreshListenable ?? kIdleListenable;

    return Scaffold(
      appBar: AppBar(title: const Text('Jamii ya Wakulima')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppFeedback.tap();
          AppNavigator.pushCreateCommunityPost(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Swali'),
      ),
      body: AppLayout(
        child: ListenableBuilder(
        listenable: refreshListenable,
        builder: (context, _) {
          final cached = dependencies.cachedRepository;
          if (cached?.isInitialLoadPending == true) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: const [CommunityFeedSkeleton()],
            );
          }

          final allPosts = [
            ...context.session.state.localPosts,
            ...dependencies.communityRepository.posts,
          ];
          final posts = _filteredPosts(context);

          return FadeInContent(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                key: AppPageStorage.community,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        CommunitySummaryCard(posts: allPosts),
                        const SizedBox(height: AppSpacing.lg),
                        CommunityFilters(
                          selectedFilter: _selectedFilter,
                          onSelected: (filter) =>
                              setState(() => _selectedFilter = filter),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ]),
                    ),
                  ),
                  if (posts.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.forum_outlined,
                          title: _selectedFilter == 'Zote'
                              ? 'Hakuna machapisho bado'
                              : 'Hakuna machapisho kwa "$_selectedFilter"',
                          body: _selectedFilter == 'Zote'
                              ? 'Kuwa wa kwanza kuuliza swali au shiriki uzoefu wako na wakulima wengine.'
                              : 'Jaribu chaguo lingine la mada au angalia machapisho yote.',
                          actionLabel: _selectedFilter == 'Zote'
                              ? 'Tuma Swali'
                              : 'Ona Zote',
                          onAction: () {
                            if (_selectedFilter == 'Zote') {
                              AppNavigator.pushCreateCommunityPost(context);
                              return;
                            }
                            setState(() => _selectedFilter = 'Zote');
                          },
                        ),
                      ),
                    )
                  else
                    AdaptiveCatalogSliver(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      listItemSpacing: AppSpacing.lg,
                      gridMainAxisExtent: 300,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final compact = AppBreakpoints.isExpanded(context);
                        return CommunityPostCard(
                          post: post,
                          compact: compact,
                          onOpen: () =>
                              AppNavigator.pushCommunityPost(context, post),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
  bool _isSendingReply = false;
  bool _isReporting = false;

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
    if (_isSendingReply) return;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSendingReply = true);
    final session = context.session;
    final author = session.isSignedIn ? session.phoneNumber! : 'Wewe';
    try {
      final reply = await context.dependencies.communityService.addReply(
        postId: _postId,
        author: author,
        body: text,
      );
      await session.addCommunityReplyRecord(_postId, reply);
      _replyController.clear();
      if (!mounted) return;
      showSnack(context, 'Jibu limehifadhiwa.');
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  Future<void> _reportPost() async {
    if (_isReporting) return;
    AppFeedback.tap();
    setState(() => _isReporting = true);
    final session = context.session;
    final communityService = context.dependencies.communityService;
    try {
      await communityService.reportPost(_postId);
      await session.reportCommunityPost(_postId);
      if (!mounted) return;
      showSnack(context, 'Ripoti imepokelewa.');
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final reported = context.session.isPostReported(_postId);
    final replies = _replies(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Majadiliano'),
        actions: [
          IconButton(
            tooltip: reported ? 'Post imeripotiwa' : 'Ripoti post',
            onPressed: reported || _isReporting ? null : _reportPost,
            icon: Icon(reported ? Icons.flag : Icons.flag_outlined),
          ),
        ],
      ),
      body: AppLayout(
        child: CustomScrollView(
        key: AppPageStorage.communityPost(_postId),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            sliver: SliverList(
            delegate: SliverChildListDelegate([
              CommunityPostCard(post: post, onOpen: () {}),
              const SizedBox(height: AppSpacing.md),
              DiscussionActionPanel(post: post),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Majibu ya wakulima',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (replies.isEmpty)
                Card(
                  color: context.colors.surfaceMuted,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Hakuna majibu bado. Kuwa wa kwanza kusaidia mkulima mwenzako.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                  ),
                ),
            ]),
            ),
          ),
          if (replies.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList.builder(
                itemCount: replies.length,
                itemBuilder: (context, index) =>
                    CommunityReplyTile(reply: replies[index]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
      bottomNavigationBar: ChatComposerBar(
        controller: _replyController,
        isLoading: _isSendingReply,
        hintText: 'Andika jibu la kusaidia...',
        sendButtonKey: const ValueKey('community-send-reply'),
        onSend: _sendReply,
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
  bool _isSubmitting = false;

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
    if (_isSubmitting) return;
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
    setState(() => _isSubmitting = true);
    final session = context.session;
    final author = session.isSignedIn ? session.phoneNumber! : 'Wewe';
    try {
      final tags = _tags.toList()..sort();
      final post = await context.dependencies.communityService.createPost(
        author: author,
        content: content,
        location: location,
        tags: tags,
      );
      await session.setPreferredLocation(location);
      await session.addCommunityPostRecord(post);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, 'Post imetumwa kwenye jamii.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuma Swali')),
      body: AppLayout(
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppTextField(
            controller: _contentController,
            labelText: 'Swali au changamoto',
            hintText: 'Mfano: Majani ya nyanya yana madoa ya njano...',
            minLines: 4,
            maxLines: 7,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _locationController,
            labelText: 'Eneo',
            hintText: 'Mfano: Morogoro',
            prefixIcon: const Icon(Icons.place_outlined),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Chagua mada', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in _availableTags)
                FilterChip(
                  selected: _tags.contains(tag),
                  selectedColor: context.colors.primaryContainer,
                  checkmarkColor: context.colors.primary,
                  side: BorderSide(
                    color: _tags.contains(tag)
                        ? context.colors.primary
                        : context.colors.borderSubtle,
                  ),
                  label: Text(tag),
                  onSelected: (selected) {
                    AppFeedback.selection();
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
          const SizedBox(height: AppSpacing.xxl),
          FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : () {
                    AppFeedback.tap();
                    _submit();
                  },
            icon: const Icon(Icons.send),
            label: const Text('Tuma kwenye Jamii'),
          ),
        ],
      ),
      ),
    );
  }
}
