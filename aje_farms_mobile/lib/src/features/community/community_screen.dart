// ignore_for_file: use_key_in_widget_constructors

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/build_flags.dart';
import '../../ui.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'Zote';
  bool _isAcceptingTerms = false;

  Future<void> _acceptTerms() async {
    if (_isAcceptingTerms) return;
    setState(() => _isAcceptingTerms = true);
    final authService = context.dependencies.authService;
    final session = context.session;
    try {
      final authSession = await authService.acceptCommunityTerms();
      await session.syncProfileFromAuthSession(authSession);
      if (mounted) showSuccessSnack(context, 'Masharti yamekubaliwa.');
    } on AuthException catch (error) {
      if (mounted) showErrorSnack(context, error.message);
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, 'Imeshindikana kuhifadhi makubaliano.');
      }
    } finally {
      if (mounted) setState(() => _isAcceptingTerms = false);
    }
  }

  List<CommunityPost> _filteredPosts(BuildContext context) {
    final session = context.session;
    final posts = session.state.communityPostsMergedWith(
      context.dependencies.communityRepository.posts,
    );
    final selected = _effectiveFilter(context);
    if (selected == 'Zote') return posts;
    return posts.where((post) => post.tags.contains(selected)).toList();
  }

  String _effectiveFilter(BuildContext context) {
    final topics = context.dependencies.communityRepository.communityTopics;
    return topics.contains(_selectedFilter) ? _selectedFilter : 'Zote';
  }

  Future<void> _handleRefresh() async {
    await context.dependencies.refreshCatalog();
    if (!mounted) return;
    showSnack(context, 'Jamii imesasishwa.');
  }

  @override
  Widget build(BuildContext context) {
    if (context.session.isSignedIn &&
        context.session.state.termsAcceptedVersion != currentTermsVersion) {
      return Scaffold(
        appBar: AppBar(title: const Text('Jamii ya Wakulima')),
        body: AppLayout(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              EmptyState(
                icon: Icons.gavel_outlined,
                title: 'Kubali usalama wa jamii',
                body:
                    'Kabla ya kuchapisha au kujibu, soma Masharti ya Matumizi na Mwongozo wa Jamii. Usichapishe vitisho, chuki, spam, taarifa binafsi au ushauri hatari.',
                actionLabel: _isAcceptingTerms
                    ? 'Inahifadhi...'
                    : 'Nakubali na Kuendelea',
                onAction: _isAcceptingTerms ? null : _acceptTerms,
              ),
              if (privacyPolicyUrl.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _openCommunityPolicy('/terms'),
                      child: const Text('Masharti ya Matumizi'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _openCommunityPolicy('/community-guidelines'),
                      child: const Text('Mwongozo wa Jamii'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }
    final dependencies = context.dependencies;
    final refreshListenable = dependencies.refreshListenable ?? kIdleListenable;

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

            final allPosts = context.session.state.communityPostsMergedWith(
              dependencies.communityRepository.posts,
            );
            final selectedFilter = _effectiveFilter(context);
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
                            topics: dependencies
                                .communityRepository.communityTopics,
                            selectedFilter: selectedFilter,
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
                            title: selectedFilter == 'Zote'
                                ? 'Hakuna machapisho bado'
                                : 'Hakuna machapisho kwa "$_selectedFilter"',
                            body: selectedFilter == 'Zote'
                                ? 'Kuwa wa kwanza kuuliza swali au shiriki uzoefu wako na wakulima wengine.'
                                : 'Jaribu chaguo lingine la mada au angalia machapisho yote.',
                            actionLabel: selectedFilter == 'Zote'
                                ? 'Tuma Swali'
                                : 'Ona Zote',
                            onAction: () {
                              if (selectedFilter == 'Zote') {
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

Future<void> _openCommunityPolicy(String path) async {
  final base = Uri.tryParse(privacyPolicyUrl);
  if (base == null) return;
  await launchUrl(base.resolve(path), mode: LaunchMode.externalApplication);
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
  bool _isBlocking = false;

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
    try {
      final reply = await context.dependencies.communityService.addReply(
        postId: _postId,
        body: text,
      );
      await session.addCommunityReplyRecord(_postId, reply);
      _replyController.clear();
      if (!mounted) return;
      showSuccessSnack(context, 'Jibu limehifadhiwa.');
    } on CommunityException catch (error) {
      if (!mounted) return;
      // The draft is deliberately left in the composer so a retry does not
      // force the user to retype their reply.
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: _sendReply,
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Imeshindikana kutuma jibu. Angalia mtandao wako.',
        actionLabel: 'Jaribu tena',
        onAction: _sendReply,
      );
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  Future<void> _reportPost({bool reportAuthor = false}) async {
    if (_isReporting) return;
    AppFeedback.tap();
    final reason = await _selectCommunityReportReason(context);
    if (reason == null || !mounted) return;
    setState(() => _isReporting = true);
    final session = context.session;
    final communityService = context.dependencies.communityService;
    try {
      if (reportAuthor) {
        await communityService.reportAuthor(_postId, reason: reason);
      } else {
        await communityService.reportPost(_postId, reason: reason);
      }
      await session.reportCommunityPost(_postId);
      if (!mounted) return;
      showSuccessSnack(
        context,
        reportAuthor
            ? 'Ripoti ya mtumiaji imepokelewa.'
            : 'Ripoti ya post imepokelewa.',
      );
    } on CommunityException catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: () => _reportPost(reportAuthor: reportAuthor),
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Imeshindikana kutuma ripoti. Angalia mtandao wako.',
        actionLabel: 'Jaribu tena',
        onAction: () => _reportPost(reportAuthor: reportAuthor),
      );
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  Future<void> _blockAuthor() async {
    if (_isBlocking) return;
    final confirmed = await confirmAction(
      context,
      title: 'Zuia ${widget.post.author}?',
      message:
          'Hutaona tena machapisho ya mtumiaji huyu kwenye jamii. Unaweza kuwasiliana na msaada ukitaka kuondoa kizuizi.',
      confirmLabel: 'Zuia',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isBlocking = true);
    final dependencies = context.dependencies;
    try {
      await dependencies.communityService.blockAuthor(_postId);
      await dependencies.refreshCatalog();
      if (!mounted) return;
      showSuccessSnack(context, 'Mtumiaji amezuiwa.');
      Navigator.of(context).pop();
    } on CommunityException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Imeshindikana kumzuia mtumiaji.');
    } finally {
      if (mounted) setState(() => _isBlocking = false);
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
          PopupMenuButton<String>(
            tooltip: 'Usalama wa jamii',
            enabled: !_isReporting && !_isBlocking,
            onSelected: (action) {
              if (action == 'report_post') _reportPost();
              if (action == 'report_author') {
                _reportPost(reportAuthor: true);
              }
              if (action == 'block_author') _blockAuthor();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report_post',
                enabled: !reported,
                child: Text(reported ? 'Post imeripotiwa' : 'Ripoti post'),
              ),
              const PopupMenuItem(
                value: 'report_author',
                child: Text('Ripoti mtumiaji'),
              ),
              const PopupMenuItem(
                value: 'block_author',
                child: Text('Zuia mtumiaji'),
              ),
            ],
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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

Future<String?> _selectCommunityReportReason(BuildContext context) {
  const reasons = <String, String>{
    'spam': 'Taka au matangazo yasiyofaa',
    'harassment': 'Unyanyasaji au vitisho',
    'hate': 'Chuki dhidi ya kundi',
    'sexual': 'Maudhui ya kingono',
    'violence': 'Vurugu au maudhui hatari',
    'misinformation': 'Taarifa hatari au ya kupotosha',
    'privacy': 'Taarifa binafsi imewekwa wazi',
    'other': 'Sababu nyingine',
  };
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Kwa nini unaripoti?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in reasons.entries)
            ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.of(context).pop(entry.key),
            ),
        ],
      ),
    ),
  );
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
  final _contentFocus = FocusNode();
  final _locationFocus = FocusNode();
  final Set<String> _tags = {};
  bool _initializedLocation = false;
  bool _isSubmitting = false;
  String? _contentError;
  String? _locationError;
  Uint8List? _pickedImageBytes;
  String? _pickedImageContentType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLocation) {
      _locationController.text = context.session.state.preferredLocation ?? '';
      _initializedLocation = true;
    }
    _reconcileTags(context.dependencies.communityRepository.communityTopics);
  }

  void _reconcileTags(List<String> topics) {
    _tags.removeWhere((tag) => !topics.contains(tag));
    if (_tags.isEmpty) _tags.add(topics.first);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _contentFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final contentType = _contentTypeForXFile(picked);
    if (contentType == null) {
      if (!mounted) return;
      showSnack(context, 'Aina ya picha haikubaliki. Tumia JPG, PNG au WEBP.');
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageContentType = contentType;
    });
  }

  void _removeImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageContentType = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _reconcileTags(context.dependencies.communityRepository.communityTopics);
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();
    // Validate both fields in one pass so the user sees every problem at once,
    // then focus the first offending field.
    final contentError = content.length < 12
        ? 'Andika maelezo ya kutosha (angalau herufi 12) kuhusu changamoto.'
        : null;
    final locationError = location.isEmpty
        ? 'Weka eneo lako ili wakulima wakuelewe vizuri.'
        : null;
    if (contentError != null || locationError != null) {
      AppFeedback.error();
      setState(() {
        _contentError = contentError;
        _locationError = locationError;
      });
      (contentError != null ? _contentFocus : _locationFocus).requestFocus();
      return;
    }
    setState(() {
      _contentError = null;
      _locationError = null;
      _isSubmitting = true;
    });
    final session = context.session;
    final communityService = context.dependencies.communityService;
    try {
      final tags = _tags.toList()..sort();
      String? imagePath;
      final imageBytes = _pickedImageBytes;
      final imageContentType = _pickedImageContentType;
      if (imageBytes != null && imageContentType != null) {
        imagePath = await communityService.uploadImage(
          bytes: imageBytes,
          contentType: imageContentType,
        );
        if (imagePath == null && mounted) {
          showErrorSnack(
            context,
            'Imeshindikana kupakia picha; post itatumwa bila picha.',
          );
        }
      }
      final post = await communityService.createPost(
        content: content,
        location: location,
        tags: tags,
        imagePath: imagePath,
      );
      await session.setPreferredLocation(location);
      await session.addCommunityPostRecord(post);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Post imetumwa kwenye jamii.');
    } on CommunityException catch (error) {
      // Previously there was no catch here at all: a failed post threw, the
      // draft stayed on screen, and the user got no explanation.
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: _submit,
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Imeshindikana kutuma post. Angalia mtandao wako.',
        actionLabel: 'Jaribu tena',
        onAction: _submit,
      );
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
              focusNode: _contentFocus,
              labelText: 'Swali au changamoto',
              hintText: 'Mfano: Majani ya nyanya yana madoa ya njano...',
              minLines: 4,
              maxLines: 7,
              enabled: !_isSubmitting,
              errorText: _contentError,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_contentError != null) setState(() => _contentError = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _locationController,
              focusNode: _locationFocus,
              labelText: 'Eneo',
              hintText: 'Mfano: Morogoro',
              prefixIcon: const Icon(Icons.place_outlined),
              enabled: !_isSubmitting,
              errorText: _locationError,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_locationError != null) {
                  setState(() => _locationError = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Chagua mada', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag
                    in context.dependencies.communityRepository.communityTopics)
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
            const SizedBox(height: AppSpacing.lg),
            Text('Ongeza picha (hiari)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (_pickedImageBytes != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.memory(
                      _pickedImageBytes!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _isSubmitting ? null : _removeImage,
                    icon: const Icon(Icons.close),
                    tooltip: 'Ondoa picha',
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        AppFeedback.tap();
                        _pickImage();
                      },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Chagua picha'),
              ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      AppFeedback.tap();
                      _submit();
                    },
              // Uploading an image over a rural connection can take a while;
              // without a spinner the disabled button reads as broken.
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Inatuma...' : 'Tuma kwenye Jamii'),
            ),
          ],
        ),
      ),
    );
  }
}

String? _contentTypeForXFile(XFile file) {
  final mimeType = file.mimeType?.toLowerCase();
  if (mimeType == 'image/jpeg' ||
      mimeType == 'image/png' ||
      mimeType == 'image/webp') {
    return mimeType;
  }
  final extension = file.name.toLowerCase().split('.').last;
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return null;
  }
}
