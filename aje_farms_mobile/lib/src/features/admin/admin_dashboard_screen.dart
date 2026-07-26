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
  String? titleError;
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
                        errorText: titleError,
                      ),
                      onChanged: (_) {
                        if (titleError != null) {
                          setSheetState(() => titleError = null);
                        }
                      },
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
                        if (title.isEmpty) {
                          // Previously this returned silently, leaving the
                          // admin tapping Save with no indication why nothing
                          // happened.
                          AppFeedback.error();
                          setSheetState(
                            () => titleError = 'Jina haliwezi kuwa tupu.',
                          );
                          return;
                        }
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

Future<_CourseEditResult?> _showCourseEditor({
  required BuildContext context,
  required AdminContentCourseRecord record,
}) {
  return Navigator.of(context).push<_CourseEditResult>(
    MaterialPageRoute(
      builder: (_) => _CourseCurriculumEditor(record: record),
      fullscreenDialog: true,
    ),
  );
}

class _CourseCurriculumEditor extends StatefulWidget {
  const _CourseCurriculumEditor({required this.record});

  final AdminContentCourseRecord record;

  @override
  State<_CourseCurriculumEditor> createState() =>
      _CourseCurriculumEditorState();
}

class _CourseCurriculumEditorState extends State<_CourseCurriculumEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late String _status;
  late List<_LessonDraft> _lessons;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _title = record.course.title;
    _description = record.course.description;
    _status = record.status == 'approved' ? 'approved' : 'draft';
    _lessons = [
      for (final lesson in record.course.lessons)
        _LessonDraft.fromLesson(lesson),
    ];
  }

  void _addLesson({bool newSection = false}) {
    AppFeedback.tap();
    setState(() {
      final previous = _lessons.isEmpty ? null : _lessons.last;
      _lessons.add(
        _LessonDraft(
          key: UniqueKey(),
          moduleId: newSection ? null : previous?.moduleId,
          moduleKey: newSection
              ? 'new-${DateTime.now().microsecondsSinceEpoch}-${_lessons.length}'
              : previous?.moduleKey,
          moduleTitle: newSection
              ? 'Sehemu mpya'
              : previous?.moduleTitle ?? 'Sehemu mpya',
          title: '',
          type: LessonType.reading,
          durationMinutes: 5,
          body: '',
          videoUrl: '',
        ),
      );
    });
  }

  Future<void> _removeLesson(int index) async {
    final lesson = _lessons[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ondoa somo?'),
        content: Text(
          lesson.title.trim().isEmpty
              ? 'Somo hili jipya litaondolewa kwenye mtaala.'
              : '“${lesson.title}” litaondolewa kwenye mtaala baada ya kuhifadhi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ondoa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppFeedback.tap();
    setState(() => _lessons.removeAt(index));
  }

  void _save() {
    setState(() => _showValidation = true);
    if (!_formKey.currentState!.validate()) {
      AppFeedback.error();
      return;
    }
    if (_lessons.isEmpty) {
      AppFeedback.error();
      showErrorSnack(
        context,
        'Kozi lazima iwe na angalau somo moja.',
      );
      return;
    }
    _formKey.currentState!.save();
    final draftError = _firstDraftError();
    if (draftError != null) {
      AppFeedback.error();
      showErrorSnack(context, draftError);
      return;
    }
    final original = widget.record.course;
    final outcomes = <String>[];
    for (final lesson in _lessons) {
      final module = lesson.moduleTitle.trim();
      if (!outcomes.contains(module)) outcomes.add(module);
    }
    final course = Course(
      id: original.id,
      title: _title.trim(),
      description: _description.trim(),
      badge: original.badge,
      icon: original.icon,
      progress: original.progress,
      imageUrl: original.imageUrl,
      outcomes: outcomes,
      lessons: [
        for (final draft in _lessons)
          Lesson(
            id: draft.id,
            moduleId: draft.moduleId,
            moduleKey: draft.moduleKey,
            moduleTitle: draft.moduleTitle.trim(),
            title: draft.title.trim(),
            type: draft.type,
            meta: 'Dakika ${draft.durationMinutes}',
            description: draft.body.trim(),
            durationMinutes: draft.durationMinutes,
            resourceUrl:
                draft.videoUrl.trim().isEmpty ? null : draft.videoUrl.trim(),
            isLearnerVisible: draft.isLearnerVisible,
            readinessReasons: draft.readinessReasons,
          ),
      ],
    );
    AppFeedback.tap();
    Navigator.of(context).pop(
      _CourseEditResult(course: course, status: _status),
    );
  }

  String? _firstDraftError() {
    for (var index = 0; index < _lessons.length; index += 1) {
      final lesson = _lessons[index];
      final number = index + 1;
      if (lesson.moduleTitle.trim().isEmpty) {
        return 'Somo la $number linahitaji jina la sehemu.';
      }
      if (lesson.title.trim().isEmpty) {
        return 'Somo la $number linahitaji jina.';
      }
      if (lesson.durationMinutes <= 0) {
        return 'Somo la $number linahitaji dakika zaidi ya sifuri.';
      }
      if (lesson.type == LessonType.reading && lesson.body.trim().isEmpty) {
        return 'Somo la $number linahitaji maandishi.';
      }
      final videoUrl = lesson.videoUrl.trim();
      if (videoUrl.isNotEmpty) {
        final uri = Uri.tryParse(videoUrl);
        if (uri == null ||
            (uri.scheme != 'https' && uri.scheme != 'http') ||
            uri.host.isEmpty) {
          return 'Somo la $number lina kiungo cha video kisicho sahihi.';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hariri mtaala'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Hifadhi'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidation
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                'Taarifa za kozi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Jina la kozi'),
                validator: _requiredField('Jina haliwezi kuwa tupu.'),
                onSaved: (value) => _title = value ?? '',
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: _description,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Maelezo ya kozi',
                  alignLabelWithHint: true,
                ),
                validator: _requiredField('Maelezo hayawezi kuwa tupu.'),
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Hali ya uchapishaji',
                style: Theme.of(context).textTheme.labelLarge,
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
                    label: Text('Chapisha'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (next) {
                  AppFeedback.selection();
                  setState(() => _status = next.first);
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sehemu na masomo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Pill(
                    label: '${_lessons.length}',
                    color: context.colors.surfaceMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hariri sehemu, kichwa, maandishi, muda na video. '
                'Buruta kadi kubadilisha mpangilio. Masomo mapya au maudhui '
                'yaliyobadilishwa huwekwa kwenye ukaguzi wa vyanzo kabla ya '
                'kuonekana kwa wanafunzi.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.muted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _lessons.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final lesson = _lessons.removeAt(oldIndex);
                    _lessons.insert(newIndex, lesson);
                  });
                },
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  return _CurriculumLessonCard(
                    key: lesson.key,
                    index: index,
                    lesson: lesson,
                    onRemove: () => _removeLesson(index),
                    onModuleTitleChanged: (value) {
                      setState(() {
                        for (final candidate in _lessons) {
                          final sameModule =
                              candidate.moduleKey == lesson.moduleKey;
                          if (sameModule) candidate.moduleTitle = value;
                        }
                      });
                    },
                    onTypeChanged: (value) {
                      setState(() => lesson.type = value);
                    },
                  );
                },
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addLesson,
                    icon: const Icon(Icons.add),
                    label: const Text('Ongeza somo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _addLesson(newSection: true),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Ongeza sehemu'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Hifadhi mtaala mzima'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurriculumLessonCard extends StatelessWidget {
  const _CurriculumLessonCard({
    required super.key,
    required this.index,
    required this.lesson,
    required this.onRemove,
    required this.onModuleTitleChanged,
    required this.onTypeChanged,
  });

  final int index;
  final _LessonDraft lesson;
  final VoidCallback onRemove;
  final ValueChanged<String> onModuleTitleChanged;
  final ValueChanged<LessonType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        maintainState: true,
        initiallyExpanded: index == 0,
        leading: Semantics(
          label: 'Hamisha somo la ${index + 1}',
          button: true,
          child: SizedBox.square(
            dimension: 48,
            child: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ),
        ),
        title: Text(
          lesson.title.trim().isEmpty ? 'Somo jipya' : lesson.title,
        ),
        subtitle: Text(
          '${lesson.moduleTitle} · ${lesson.type.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          TextFormField(
            initialValue: lesson.moduleTitle,
            decoration: const InputDecoration(labelText: 'Jina la sehemu'),
            validator: _requiredField('Jina la sehemu linahitajika.'),
            onChanged: onModuleTitleChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: lesson.title,
            decoration: const InputDecoration(labelText: 'Jina la somo'),
            validator: _requiredField('Jina la somo linahitajika.'),
            onSaved: (value) => lesson.title = value ?? '',
            onChanged: (value) => lesson.title = value,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<LessonType>(
            initialValue: lesson.type,
            decoration: const InputDecoration(labelText: 'Aina ya somo'),
            items: [
              for (final type in LessonType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                ),
            ],
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: '${lesson.durationMinutes}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Muda (dakika)'),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              return parsed == null || parsed <= 0
                  ? 'Weka dakika zaidi ya sifuri.'
                  : null;
            },
            onSaved: (value) {
              lesson.durationMinutes = int.tryParse(value?.trim() ?? '') ?? 5;
            },
            onChanged: (value) {
              lesson.durationMinutes =
                  int.tryParse(value.trim()) ?? lesson.durationMinutes;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: lesson.body,
            minLines: 4,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: lesson.type == LessonType.video
                  ? 'Maelezo ya video'
                  : 'Maandishi ya somo',
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (lesson.type == LessonType.reading &&
                  (value == null || value.trim().isEmpty)) {
                return 'Maandishi ya somo yanahitajika.';
              }
              return null;
            },
            onSaved: (value) => lesson.body = value ?? '',
            onChanged: (value) => lesson.body = value,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: lesson.videoUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Kiungo cha video (hiari kwa video iliyohifadhiwa)',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              final uri = Uri.tryParse(text);
              if (text.isEmpty ||
                  (uri != null &&
                      (uri.scheme == 'https' || uri.scheme == 'http') &&
                      uri.host.isNotEmpty)) {
                return null;
              }
              return 'Weka kiungo kamili cha video.';
            },
            onSaved: (value) => lesson.videoUrl = value ?? '',
            onChanged: (value) => lesson.videoUrl = value,
          ),
          if (lesson.readinessReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.pastelPanel(
                context,
                context.colors.surfacePeach,
              ),
              child: Text(
                'Kabla ya kuonekana kwa mwanafunzi:\n'
                '${lesson.readinessReasons.map((reason) => '• $reason').join('\n')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Ondoa somo'),
            ),
          ),
        ],
      ),
    );
  }
}

String? Function(String?) _requiredField(String message) {
  return (value) => value == null || value.trim().isEmpty ? message : null;
}

class _AdminContentTab extends StatefulWidget {
  const _AdminContentTab();

  @override
  State<_AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends State<_AdminContentTab> {
  bool _didRequestInitialLoad = false;
  bool _loading = true;
  String? _error;
  List<AdminContentCourseRecord> _courses = const [];
  List<AdminContentDocumentRecord> _documents = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The initial load must not run from initState: it reads
    // `context.dependencies`, an InheritedWidget, which Flutter forbids before
    // initState completes. Doing so threw on every mount and the generic catch
    // turned it into a permanent "failed to load" state.
    if (_didRequestInitialLoad) return;
    _didRequestInitialLoad = true;
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
    final result = await _showCourseEditor(
      context: context,
      record: record,
    );
    if (result == null) return;
    try {
      await adminService.upsertContentCourse(
        course: result.course,
        status: result.status,
        baseUpdatedAt: record.updatedAt,
      );
      if (!mounted) return;
      showSuccessSnack(context, 'Kozi imehifadhiwa.');
      _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: () => _editCourse(record),
      );
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
      showSuccessSnack(context, 'Document imehifadhiwa.');
      _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: () => _editDocument(record),
      );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${record.course.lessons.length} masomo'
                            '${record.course.lessons.any((lesson) => lesson.type == LessonType.video) ? ' · Ina video' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _AdminStatusPill(status: record.status),
                        ],
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
  bool _didRequestInitialLoad = false;
  bool _loading = true;
  String? _error;
  List<AdminModerationReport> _reports = const [];
  String? _resolvingPostId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The initial load must not run from initState: it reads
    // `context.dependencies`, an InheritedWidget, which Flutter forbids before
    // initState completes. Doing so threw on every mount and the generic catch
    // turned it into a permanent "failed to load" state.
    if (_didRequestInitialLoad) return;
    _didRequestInitialLoad = true;
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
    // Hiding a post is visible to the community and not undoable from this
    // screen, so require an explicit confirmation first.
    if (action == 'hide') {
      final confirmed = await confirmAction(
        context,
        title: 'Ficha chapisho?',
        message:
            'Chapisho hili hakitaonekana kwa wakulima wengine. Unaweza kubadilisha hili kwenye backend tu.',
        confirmLabel: 'Ficha',
        isDestructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _resolvingPostId = report.post.id);
    try {
      await context.dependencies.adminService.resolveModerationReport(
        postId: report.post.id,
        action: action,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        action == 'hide' ? 'Chapisho limefichwa.' : 'Ripoti imeondolewa.',
      );
      await _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: () => _resolve(report, action),
      );
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
                      Builder(
                        builder: (context) {
                          final isResolving =
                              _resolvingPostId == report.post.id;
                          return Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              // Dismissing the report is the safe, reversible
                              // choice, so it carries the primary emphasis.
                              FilledButton.icon(
                                onPressed: isResolving
                                    ? null
                                    : () {
                                        AppFeedback.tap();
                                        _resolve(report, 'dismiss');
                                      },
                                icon: isResolving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.close),
                                label: const Text('Ondoa ripoti'),
                              ),
                              // Hiding is destructive: outlined and tinted with
                              // the semantic error colour so it never reads as
                              // the default action.
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.colors.error,
                                  side: BorderSide(
                                    color: context.colors.error,
                                  ),
                                ),
                                onPressed: isResolving
                                    ? null
                                    : () {
                                        AppFeedback.tap();
                                        _resolve(report, 'hide');
                                      },
                                icon: const Icon(Icons.visibility_off_outlined),
                                label: const Text('Ficha chapisho'),
                              ),
                            ],
                          );
                        },
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
  bool _didRequestInitialLoad = false;
  bool _loading = true;
  String? _error;
  AdminUsersPage _page = const AdminUsersPage(total: 0, users: []);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The initial load must not run from initState: it reads
    // `context.dependencies`, an InheritedWidget, which Flutter forbids before
    // initState completes. Doing so threw on every mount and the generic catch
    // turned it into a permanent "failed to load" state.
    if (_didRequestInitialLoad) return;
    _didRequestInitialLoad = true;
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
      // ListView.builder so a 100-user page only builds the rows on screen;
      // each row renders an avatar plus four activity chips.
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: _headerSlotCount + _bodyItemCount,
        itemBuilder: (context, index) {
          if (index < _headerSlotCount) return _buildHeaderSlot(context, index);
          if (_loading || _page.users.isEmpty) {
            return _buildBodyPlaceholder(context);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _AdminUserCard(user: _page.users[index - _headerSlotCount]),
          );
        },
      ),
    );
  }

  /// Search field, stale-data warning (when present), and section header.
  int get _headerSlotCount => _error == null ? 3 : 4;

  int get _bodyItemCount =>
      _loading || _page.users.isEmpty ? 1 : _page.users.length;

  Widget _buildBodyPlaceholder(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const EmptyState(
      icon: Icons.person_search_outlined,
      title: 'Hakuna matokeo',
      body: 'Badilisha utafutaji au onyesha tena baadaye.',
    );
  }

  Widget _buildHeaderSlot(BuildContext context, int index) {
    // Slot 1 only exists while an error is being shown alongside stale rows.
    final errorOffset = _error == null ? 0 : 1;
    if (index == 1 && errorOffset == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Card(
          color: context.colors.error.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: context.colors.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    // Without this the refresh failure was swallowed entirely
                    // and the admin kept reading stale rows as if current.
                    'Orodha hii si ya sasa: ${_error!}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: _load,
                  child: const Text('Jaribu tena'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (index == 0) return _buildSearchField(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _AdminSectionHeader(title: 'Watumiaji', count: _page.total),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextField(
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

class _CourseEditResult {
  const _CourseEditResult({
    required this.course,
    required this.status,
  });

  final Course course;
  final String status;
}

class _LessonDraft {
  _LessonDraft({
    required this.key,
    required this.moduleTitle,
    required this.title,
    required this.type,
    required this.durationMinutes,
    required this.body,
    required this.videoUrl,
    this.id,
    this.moduleId,
    String? moduleKey,
    this.isLearnerVisible = false,
    this.readinessReasons = const [],
  }) : moduleKey = moduleKey ?? moduleId ?? key.toString();

  factory _LessonDraft.fromLesson(Lesson lesson) {
    return _LessonDraft(
      key: ValueKey(lesson.id ?? UniqueKey()),
      id: lesson.id,
      moduleId: lesson.moduleId,
      moduleKey: lesson.moduleKey ?? lesson.moduleId,
      moduleTitle: lesson.moduleTitle ??
          'Sehemu ya ${lesson.type == LessonType.video ? 'video' : 'masomo'}',
      title: lesson.title,
      type: lesson.type,
      durationMinutes: lesson.durationMinutes ??
          int.tryParse(
              RegExp(r'\d+').firstMatch(lesson.meta)?.group(0) ?? '') ??
          5,
      body: lesson.description,
      videoUrl: lesson.resourceUrl ?? '',
      isLearnerVisible: lesson.isLearnerVisible,
      readinessReasons: lesson.readinessReasons,
    );
  }

  final Key key;
  final String? id;
  final String? moduleId;
  final String moduleKey;
  String moduleTitle;
  String title;
  LessonType type;
  int durationMinutes;
  String body;
  String videoUrl;
  final bool isLearnerVisible;
  final List<String> readinessReasons;
}
