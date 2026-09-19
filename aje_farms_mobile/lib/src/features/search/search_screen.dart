import 'dart:async';

import '../../ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    this.initialScope = SearchScope.all,
    this.initialQuery,
    super.key,
  });

  final SearchScope initialScope;
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  late SearchScope _scope = widget.initialScope;
  Timer? _debounce;
  SearchResponse? _response;
  String? _error;
  bool _loading = false;
  int _requestId = 0;
  DateTime? _lastRemoteStartedAt;
  DateTime? _retryRemoteAfter;
  Future<SearchResponse>? _remoteSearchInFlight;
  bool _rateLimited = false;
  String? _activeRequestKey;

  @override
  void initState() {
    super.initState();
    if (_normalizedQueryLength(widget.initialQuery ?? '') >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchNow());
    }
  }

  @override
  void dispose() {
    _requestId += 1;
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _searchNow);
    setState(() {});
  }

  Future<void> _searchNow() async {
    _debounce?.cancel();
    _debounce = null;
    final query = _controller.text.trim();
    final requestKey = '${normalizeSearchText(query)}|${_scope.apiValue}';
    if (_loading && _activeRequestKey == requestKey) return;
    final requestId = ++_requestId;
    if (_normalizedQueryLength(query) < 2) {
      if (mounted) {
        setState(() {
          _loading = false;
          _response = null;
          _error = null;
          _activeRequestKey = null;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _activeRequestKey = requestKey;
      _rateLimited = false;
    });
    final request = SearchRequest(
      query: query,
      scope: !_communityTermsAccepted && _scope == SearchScope.all
          ? SearchScope.learning
          : _scope,
      savedDocumentIds: context.session.state.savedDocumentIds,
      localCommunityPosts: context.session.state.localPosts,
    );
    try {
      final response = context.isDeviceOnline
          ? await _searchOnlineWithFallback(request, requestId)
          : await context.dependencies.offlineSearchService.search(request);
      if (!mounted || requestId != _requestId) return;
      final visibleResponse = SearchResponse(
        query: response.query,
        scope: _scope,
        results: _communityTermsAccepted
            ? response.results
            : response.results
                .where((result) => result.kind != SearchResultKind.community)
                .toList(),
        truncated: response.truncated,
        isOffline: response.isOffline,
      );
      setState(() {
        _response = visibleResponse;
        _loading = false;
        _activeRequestKey = null;
      });
    } on _SupersededSearch {
      return;
    } on SearchException catch (error) {
      if (!mounted || requestId != _requestId) return;
      if (error.isAuthenticationFailure) {
        await _handleAuthenticationFailure();
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
        _activeRequestKey = null;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'Utafutaji haukukamilika. Jaribu tena.';
        _loading = false;
        _activeRequestKey = null;
      });
    }
  }

  Future<void> _handleAuthenticationFailure() async {
    final dependencies = context.dependencies;
    final session = context.session;
    dependencies.cachedRepository?.clearProtectedContent();
    try {
      await dependencies.authService.signOut();
    } catch (_) {
      // Local protected data must still be cleared if the remote sign-out fails.
    }
    await session.signOut();
    if (mounted) AppNavigator.replaceWithAuth(context);
  }

  Future<SearchResponse> _searchOnlineWithFallback(
    SearchRequest request,
    int requestId,
  ) async {
    final retryRemoteAfter = _retryRemoteAfter;
    if (retryRemoteAfter != null && DateTime.now().isBefore(retryRemoteAfter)) {
      _rateLimited = true;
      return context.dependencies.offlineSearchService.search(request);
    }
    final inFlight = _remoteSearchInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // The waiting latest request still gets its own remote attempt below.
      }
      if (!mounted || requestId != _requestId) {
        throw const _SupersededSearch();
      }
    }
    final previousStart = _lastRemoteStartedAt;
    if (previousStart != null) {
      final remaining = const Duration(milliseconds: 500) -
          DateTime.now().difference(previousStart);
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    }
    if (!mounted || requestId != _requestId) {
      throw const _SupersededSearch();
    }
    _lastRemoteStartedAt = DateTime.now();
    final remoteSearch = context.dependencies.searchService.search(request);
    _remoteSearchInFlight = remoteSearch;
    try {
      return await remoteSearch;
    } on SearchException catch (error) {
      if (!error.isRecoverableFailure) rethrow;
      if (error.statusCode == 429) {
        _rateLimited = true;
        _retryRemoteAfter = DateTime.now().add(
          error.retryAfter ?? const Duration(seconds: 1),
        );
      }
      return context.dependencies.offlineSearchService.search(request);
    } on TimeoutException {
      return context.dependencies.offlineSearchService.search(request);
    } finally {
      if (identical(_remoteSearchInFlight, remoteSearch)) {
        _remoteSearchInFlight = null;
      }
    }
  }

  void _selectScope(SearchScope scope) {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    _searchNow();
  }

  bool get _communityTermsAccepted =>
      context.session.state.termsAcceptedVersion == currentTermsVersion;

  List<Widget> _resultWidgets(SearchResponse response) {
    final best = response.results.take(5).toList();
    final remaining = response.results.skip(5).toList();
    final groups = <(String, Set<SearchResultKind>)>[
      (
        'Mafunzo'.tr(context),
        {
          SearchResultKind.course,
          SearchResultKind.lesson,
          SearchResultKind.problem,
        },
      ),
      ('Nyaraka'.tr(context), {SearchResultKind.document}),
      ('Jamii'.tr(context), {SearchResultKind.community}),
    ];
    return [
      if (best.isNotEmpty) ...[
        Text('Matokeo bora'.tr(context), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final result in best)
          _SearchResultTile(
            result: result,
            onTap: () => unawaited(_openResult(result)),
          ),
      ],
      for (final group in groups)
        if (remaining.any((result) => group.$2.contains(result.kind))) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(group.$1, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final result
              in remaining.where((result) => group.$2.contains(result.kind)))
            _SearchResultTile(
              result: result,
              onTap: () => unawaited(_openResult(result)),
            ),
        ],
    ];
  }

  Future<void> _openResult(
    SearchResult result, {
    bool allowCatalogRefresh = true,
  }) async {
    final dependencies = context.dependencies;
    if (result.isPremium && !context.session.hasActiveAccess) {
      await AppNavigator.pushPaywall(context);
      return;
    }
    switch (result.kind) {
      case SearchResultKind.course:
        final course = dependencies.learningRepository.courses
            .where((item) => item.id == result.id)
            .firstOrNull;
        if (course != null) {
          AppNavigator.pushCourse(context, course);
        } else {
          if (allowCatalogRefresh && await _refreshCatalogForResult()) {
            return _openResult(result, allowCatalogRefresh: false);
          }
          if (!mounted) return;
          showErrorSnack(context, 'Kozi hii haiwezi kufunguka kwa sasa.');
        }
      case SearchResultKind.lesson || SearchResultKind.document:
        final course = dependencies.learningRepository.courses
            .where((item) => item.id == result.parentId)
            .firstOrNull;
        if (result.kind == SearchResultKind.document) {
          final document = dependencies.learningRepository.documents
              .where((item) => item.id == result.id)
              .firstOrNull;
          final uri = Uri.tryParse(document?.url ?? '');
          if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
            try {
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (opened) return;
            } catch (_) {
              // The parent course below is the safe in-app fallback.
            }
          }
        }
        if (!mounted) return;
        if (course != null) {
          await AppNavigator.pushCourse(
            context,
            course,
            initialLessonId:
                result.kind == SearchResultKind.lesson ? result.id : null,
          );
        } else {
          if (allowCatalogRefresh && await _refreshCatalogForResult()) {
            return _openResult(result, allowCatalogRefresh: false);
          }
          if (!mounted) return;
          showErrorSnack(context, 'Maudhui hayawezi kufunguka kwa sasa.');
        }
      case SearchResultKind.problem:
        final problem = dependencies.learningRepository.problemCategories
            .where((item) => item.title == result.title)
            .firstOrNull;
        if (problem == null &&
            allowCatalogRefresh &&
            await _refreshCatalogForResult()) {
          return _openResult(result, allowCatalogRefresh: false);
        }
        if (!mounted) return;
        await AppNavigator.pushProblem(
          context,
          initialTopic: problem?.topic,
        );
      case SearchResultKind.community:
        final posts = context.session.state.communityPostsMergedWith(
          dependencies.communityRepository.posts,
        );
        final post = posts.where((item) => item.id == result.id).firstOrNull;
        if (post != null) {
          AppNavigator.pushCommunityPost(context, post);
        } else {
          if (allowCatalogRefresh && await _refreshCatalogForResult()) {
            return _openResult(result, allowCatalogRefresh: false);
          }
          if (!mounted) return;
          showErrorSnack(context, 'Mjadala huu hauwezi kufunguka kwa sasa.');
        }
    }
  }

  Future<bool> _refreshCatalogForResult() async {
    try {
      await context.dependencies.refreshCatalog();
      return mounted;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final responseMatchesQuery =
        _response?.query == normalizeSearchText(query) &&
            _response?.scope == _scope;
    return Scaffold(
      appBar: AppBar(
        title: Text('Tafuta'.tr(context)),
        actions: const [LanguageToggleButton()],
      ),
      body: AppLayout(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          children: [
            AppTextField(
              controller: _controller,
              autofocus: true,
              labelText: 'Tafuta'.tr(context),
              hintText: 'Tafuta kozi, makala au mada...'.tr(context),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Futa utafutaji'.tr(context),
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        _onQueryChanged('');
                      },
                    ),
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _searchNow(),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final scope in SearchScope.values)
                  if (scope != SearchScope.community || _communityTermsAccepted)
                    FilterChip(
                      label: Text(scope.label.tr(context)),
                      selected: _scope == scope,
                      onSelected: (_) => _selectScope(scope),
                    ),
              ],
            ),
            if (_loading) ...[
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                liveRegion: true,
                label: 'Inatafuta'.tr(context),
                child: const LinearProgressIndicator(),
              ),
            ],
            if (responseMatchesQuery && _response?.isOffline == true) ...[
              const SizedBox(height: AppSpacing.lg),
              const _OfflineSearchNotice(),
              if (_rateLimited)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Utafutaji wa mtandaoni umesitishwa kwa muda mfupi. Subiri kisha ujaribu tena.'.tr(context),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Utafutaji haukukamilika'.tr(context),
                  body: _error!.tr(context),
                  actionLabel: 'Jaribu tena'.tr(context),
                  onAction: _searchNow,
                ),
              )
            else if (_normalizedQueryLength(query) < 2)
              _SearchSuggestions(
                topics: context.dependencies.learningRepository.homeTopics,
                onSelected: (topic) {
                  _controller.text = topic;
                  _controller.selection = TextSelection.collapsed(
                    offset: topic.length,
                  );
                  _searchNow();
                },
              )
            else if (!_loading &&
                responseMatchesQuery &&
                _response?.results.isEmpty == true)
              Semantics(
                liveRegion: true,
                child: EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Hakuna matokeo yaliyopatikana'.tr(context),
                  body: 'Jaribu neno lingine au chagua kichujio tofauti.'.tr(context),
                ),
              )
            else if (responseMatchesQuery && _response != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  '${_response!.results.length} matokeo yamepatikana.'.tr(context),
                  style: accessibleCaption(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._resultWidgets(_response!),
            ],
            if (responseMatchesQuery && _response?.truncated == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Matokeo zaidi yapo. Ongeza maelezo kwenye utafutaji wako.'.tr(context),
                  style: accessibleCaption(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

int _normalizedQueryLength(String value) =>
    normalizeSearchText(value).runes.length;

class _SupersededSearch implements Exception {
  const _SupersededSearch();
}

class _OfflineSearchNotice extends StatelessWidget {
  const _OfflineSearchNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Card(
        color: context.colors.surfacePeach,
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(
            'Matokeo yanatoka kwenye maudhui yaliyohifadhiwa. Huenda si kamili.'.tr(context),
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({required this.topics, required this.onSelected});

  final List<String> topics;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mada maarufu'.tr(context), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final topic in topics.take(8))
              ActionChip(
                avatar: const Icon(Icons.trending_up, size: 18),
                label: Text(topic.tr(context)),
                onPressed: () => onSelected(topic),
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  IconData get _icon => switch (result.kind) {
        SearchResultKind.course => Icons.menu_book_outlined,
        SearchResultKind.lesson => Icons.article_outlined,
        SearchResultKind.document => Icons.picture_as_pdf_outlined,
        SearchResultKind.problem => Icons.agriculture_outlined,
        SearchResultKind.community => Icons.forum_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: Icon(_icon, color: context.colors.primary),
        title: Text(result.title.tr(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.metadata.isNotEmpty) Text(result.metadata.tr(context)),
            if (result.snippet?.isNotEmpty == true)
              Text(
                result.snippet!.tr(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: result.isPremium
            ? const Icon(Icons.lock_outline, semanticLabel: 'Premium')
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
