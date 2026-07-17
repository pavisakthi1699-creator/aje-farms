// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.session.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Usimamizi')),
        body: const AppLayout(
          child: Center(
            child: EmptyState(
              icon: Icons.lock_outline,
              title: 'Huna ruhusa',
              body: 'Ingia kwa akaunti ya admin ili kuona dashibodi.',
            ),
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashibodi ya Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: 'Maandishi',
                icon: Icon(Icons.menu_book_outlined, size: 20),
              ),
              Tab(
                text: 'Usimamizi',
                icon: Icon(Icons.flag_outlined, size: 20),
              ),
              Tab(
                text: 'Watumiaji',
                icon: Icon(Icons.people_outline, size: 20),
              ),
            ],
          ),
        ),
        body: const AppLayout(
          child: TabBarView(
            children: [
              _AdminContentTab(),
              _AdminModerationTab(),
              _AdminUsersTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminListSkeleton extends StatelessWidget {
  const _AdminListSkeleton({this.showSearch = false});

  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        if (showSearch) ...[
          const LoadingSkeleton(height: 56, borderRadius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
        ],
        const LoadingSkeleton(height: 18, width: 140),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < 4; index += 1) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoadingSkeleton(height: 16, width: 180),
                  const SizedBox(height: AppSpacing.sm),
                  const LoadingSkeleton(height: 14, width: 120),
                  const SizedBox(height: AppSpacing.md),
                  LoadingSkeleton(
                    height: 12,
                    width: index.isEven ? 220 : 160,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _AdminStatusPill extends StatelessWidget {
  const _AdminStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final colors = context.colors;
    final Color tone;
    final IconData icon;
    final String label;
    switch (normalized) {
      case 'approved':
      case 'published':
        tone = colors.success;
        icon = Icons.check_circle_outline;
        label = 'Imeidhinishwa';
      case 'draft':
        tone = colors.warning;
        icon = Icons.edit_note_outlined;
        label = 'Rasimu';
      case 'open':
      case 'pending':
        tone = colors.accentWarm;
        icon = Icons.hourglass_top_outlined;
        label = 'Inasubiri';
      case 'dismissed':
        tone = colors.muted;
        icon = Icons.do_not_disturb_on_outlined;
        label = 'Imeondolewa';
      case 'hidden':
        tone = colors.error;
        icon = Icons.visibility_off_outlined;
        label = 'Imefichwa';
      default:
        tone = colors.primary;
        icon = Icons.info_outline;
        label = status;
    }

    return Semantics(
      label: 'Hali: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tone),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: accessibleCaption(context, color: tone).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Pill(
          label: '$count',
          color: context.colors.surfaceMuted,
        ),
      ],
    );
  }
}

Future<_ContentEditResult?> _showContentEditor({
  required BuildContext context,
  required String titleLabel,
  required String initialTitle,
  required String initialStatus,
}) async {
  final titleController = TextEditingController(text: initialTitle);
  var status = initialStatus == 'approved' ? 'approved' : 'draft';
  try {
    return await showModalBottomSheet<_ContentEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hariri content',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: titleLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Hali ya uchapishaji',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'draft',
                          label: Text('Rasimu'),
                          icon: Icon(Icons.edit_note_outlined),
                        ),
                        ButtonSegment(
                          value: 'approved',
                          label: Text('Idhinisha'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                      ],
                      selected: {status},
                      onSelectionChanged: (next) {
                        AppFeedback.selection();
                        setSheetState(() => status = next.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;
                        AppFeedback.tap();
                        Navigator.of(context).pop(
                          _ContentEditResult(title: title, status: status),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Hifadhi'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    titleController.dispose();
  }
}

class _AdminContentTab extends StatefulWidget {
  const _AdminContentTab();

  @override
  State<_AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends State<_AdminContentTab> {
  bool _loading = true;
  String? _error;
  List<AdminContentCourseRecord> _courses = const [];
  List<AdminContentDocumentRecord> _documents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.dependencies.adminService;
      final courses = await service.listContentCourses();
      final documents = await service.listContentDocuments();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _documents = documents;
        _loading = false;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindikana kupakia content ya admin.';
        _loading = false;
      });
    }
  }

  Future<void> _editCourse(AdminContentCourseRecord record) async {
    final adminService = context.dependencies.adminService;
    final result = await _showContentEditor(
      context: context,
      titleLabel: 'Jina la kozi',
      initialTitle: record.course.title,
      initialStatus: record.status,
    );
    if (result == null || result.title.isEmpty) return;
    try {
      await adminService.upsertContentCourse(
        course: Course(
          id: record.course.id,
          title: result.title,
          description: record.course.description,
          badge: record.course.badge,
          icon: record.course.icon,
          progress: record.course.progress,
          imageUrl: record.course.imageUrl,
          outcomes: record.course.outcomes,
          lessons: record.course.lessons,
        ),
        status: result.status,
      );
      if (!mounted) return;
      AppFeedback.success();
      showSnack(context, 'Kozi imehifadhiwa.');
      _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showSnack(context, error.message);
    }
  }

  Future<void> _editDocument(AdminContentDocumentRecord record) async {
    final adminService = context.dependencies.adminService;
    final result = await _showContentEditor(
      context: context,
      titleLabel: 'Jina la document',
      initialTitle: record.document.title,
      initialStatus: record.status,
    );
    if (result == null || result.title.isEmpty) return;
    try {
      await adminService.upsertContentDocument(
        document: AppDocument(
          id: record.document.id,
          title: result.title,
          courseId: record.document.courseId,
          courseTitle: record.document.courseTitle,
          description: record.document.description,
          type: record.document.type,
          sizeLabel: record.document.sizeLabel,
          url: record.document.url,
          isPremium: record.document.isPremium,
        ),
        status: result.status,
      );
      if (!mounted) return;
      AppFeedback.success();
      showSnack(context, 'Document imehifadhiwa.');
      _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showSnack(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Semantics(
        label: 'Inapakia content ya admin',
        child: const _AdminListSkeleton(),
      );
    }
    if (_error != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Imeshindikana kupakia',
          body: _error!,
          actionLabel: 'Jaribu tena',
          onAction: _load,
        ),
      );
    }
    if (_courses.isEmpty && _documents.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.library_books_outlined,
          title: 'Hakuna content bado',
          body: 'Anza kwa kuunda kozi au document kutoka backend.',
          actionLabel: 'Onyesha tena',
          onAction: _load,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _AdminSectionHeader(title: 'Kozi', count: _courses.length),
          const SizedBox(height: AppSpacing.sm),
          if (_courses.isEmpty)
            Card(
              color: context.colors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Hakuna kozi zilizopatikana.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.muted,
                      ),
                ),
              ),
            )
          else
            for (final record in _courses)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: AppDecorations.pastelPanel(
                        context,
                        context.colors.surfaceLavender,
                      ),
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: context.colors.primary,
                      ),
                    ),
                    title: Text(
                      record.course.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _AdminStatusPill(status: record.status),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Hariri kozi',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        AppFeedback.tap();
                        _editCourse(record);
                      },
                    ),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.lg),
          _AdminSectionHeader(title: 'Documents', count: _documents.length),
          const SizedBox(height: AppSpacing.sm),
          if (_documents.isEmpty)
            Card(
              color: context.colors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Hakuna documents zilizopatikana.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.muted,
                      ),
                ),
              ),
            )
          else
            for (final record in _documents)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: AppDecorations.pastelPanel(
                        context,
                        context.colors.surfacePeach,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: context.colors.primary,
                      ),
                    ),
                    title: Text(
                      record.document.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _AdminStatusPill(status: record.status),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Hariri document',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        AppFeedback.tap();
                        _editDocument(record);
                      },
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _AdminModerationTab extends StatefulWidget {
  const _AdminModerationTab();

  @override
  State<_AdminModerationTab> createState() => _AdminModerationTabState();
}

class _AdminModerationTabState extends State<_AdminModerationTab> {
  bool _loading = true;
  String? _error;
  List<AdminModerationReport> _reports = const [];
  String? _resolvingPostId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports =
          await context.dependencies.adminService.listModerationReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindikana kupakia moderation reports.';
        _loading = false;
      });
    }
  }

  Future<void> _resolve(AdminModerationReport report, String action) async {
    setState(() => _resolvingPostId = report.post.id);
    try {
      await context.dependencies.adminService.resolveModerationReport(
        postId: report.post.id,
        action: action,
      );
      if (!mounted) return;
      AppFeedback.success();
      showSnack(
        context,
        action == 'hide' ? 'Chapisho limefichwa.' : 'Ripoti imeondolewa.',
      );
      await _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showSnack(context, error.message);
    } finally {
      if (mounted) {
        setState(() => _resolvingPostId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Semantics(
        label: 'Inapakia ripoti za usimamizi',
        child: const _AdminListSkeleton(),
      );
    }
    if (_error != null) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Imeshindikana kupakia',
          body: _error!,
          actionLabel: 'Jaribu tena',
          onAction: _load,
        ),
      );
    }
    if (_reports.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.verified_outlined,
          title: 'Hakuna ripoti',
          body: 'Moderation queue iko safi kwa sasa.',
          actionLabel: 'Onyesha tena',
          onAction: _load,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _AdminSectionHeader(title: 'Ripoti', count: _reports.length),
          const SizedBox(height: AppSpacing.md),
          for (final report in _reports)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              report.post.content,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _AdminStatusPill(status: report.report.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Mwandishi: ${report.post.author}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.muted,
                            ),
                      ),
                      if (report.post.location.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Eneo: ${report.post.location}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colors.muted,
                                  ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _resolvingPostId == report.post.id
                                ? null
                                : () {
                                    AppFeedback.tap();
                                    _resolve(report, 'dismiss');
                                  },
                            icon: const Icon(Icons.close),
                            label: const Text('Ondoa ripoti'),
                          ),
                          FilledButton.icon(
                            onPressed: _resolvingPostId == report.post.id
                                ? null
                                : () {
                                    AppFeedback.tap();
                                    _resolve(report, 'hide');
                                  },
                            icon: const Icon(Icons.visibility_off_outlined),
                            label: const Text('Ficha chapisho'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  AdminUsersPage _page = const AdminUsersPage(total: 0, users: []);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.dependencies.adminService.listUsers(
        search: _searchController.text.trim(),
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindikana kupakia user monitoring.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _page.users.isEmpty && _error == null) {
      return Semantics(
        label: 'Inapakia orodha ya watumiaji',
        child: const _AdminListSkeleton(showSearch: true),
      );
    }
    if (_error != null && _page.users.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Imeshindikana kupakia',
          body: _error!,
          actionLabel: 'Jaribu tena',
          onAction: _load,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Tafuta kwa namba au jina',
              hintText: 'Mfano: +2557… au Asha',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? IconButton(
                      tooltip: 'Tafuta',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        AppFeedback.tap();
                        _load();
                      },
                    )
                  : IconButton(
                      tooltip: 'Futa utafutaji',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        AppFeedback.tap();
                        _searchController.clear();
                        setState(() {});
                        _load();
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AdminSectionHeader(title: 'Watumiaji', count: _page.total),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_page.users.isEmpty)
            const EmptyState(
              icon: Icons.person_search_outlined,
              title: 'Hakuna matokeo',
              body: 'Badilisha utafutaji au onyesha tena baadaye.',
            )
          else
            for (final user in _page.users)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AdminUserCard(user: user),
              ),
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({required this.user});

  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : user.phoneNumber;
    final roleLabel = user.role == 'admin' ? 'Admin' : 'Mkulima';
    final planLabel = user.subscriptionPlan ?? 'Hakuna kifurushi';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(
                    _initialsFor(name),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (user.displayName != null &&
                          user.displayName!.trim().isNotEmpty)
                        Text(
                          user.phoneNumber,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colors.muted,
                                  ),
                        ),
                    ],
                  ),
                ),
                Pill(
                  label: roleLabel,
                  color: user.role == 'admin'
                      ? context.colors.surfaceLavender
                      : context.colors.surfaceMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kifurushi: $planLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.muted,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ActivityStat(
                  icon: Icons.school_outlined,
                  label: 'Maendeleo',
                  value: user.learningProgressCount,
                ),
                _ActivityStat(
                  icon: Icons.payments_outlined,
                  label: 'Malipo',
                  value: user.paymentTransactionsCount,
                ),
                _ActivityStat(
                  icon: Icons.notifications_outlined,
                  label: 'Arifa',
                  value: user.notificationCount,
                ),
                _ActivityStat(
                  icon: Icons.forum_outlined,
                  label: 'Machapisho',
                  value: user.communityPostsCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: AppDecorations.pastelPanel(
          context,
          context.colors.surfaceMuted,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: context.colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$label $value',
              style: accessibleCaption(context),
            ),
          ],
        ),
      ),
    );
  }
}

String _initialsFor(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'A';
  if (parts.length == 1) {
    final token = parts.first;
    if (token.startsWith('+') && token.length >= 4) {
      return token.substring(token.length - 2);
    }
    return token.substring(0, token.length >= 2 ? 2 : 1).toUpperCase();
  }
  return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
}

class _ContentEditResult {
  const _ContentEditResult({
    required this.title,
    required this.status,
  });

  final String title;
  final String status;
}
