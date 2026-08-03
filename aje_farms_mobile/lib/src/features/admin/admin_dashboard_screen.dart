// ignore_for_file: use_key_in_widget_constructors

import 'package:image_picker/image_picker.dart';

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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashibodi ya Admin'),
          bottom: const TabBar(
            isScrollable: true,
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
              Tab(
                text: 'Malipo',
                icon: Icon(Icons.payments_outlined, size: 20),
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
              _AdminPaymentsTab(),
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
  bool isNew = false,
}) {
  return Navigator.of(context).push<_CourseEditResult>(
    MaterialPageRoute(
      builder: (_) => _CourseCurriculumEditor(record: record, isNew: isNew),
      fullscreenDialog: true,
    ),
  );
}

class _CourseCurriculumEditor extends StatefulWidget {
  const _CourseCurriculumEditor({
    required this.record,
    required this.isNew,
  });

  final AdminContentCourseRecord record;
  final bool isNew;

  @override
  State<_CourseCurriculumEditor> createState() =>
      _CourseCurriculumEditorState();
}

class _CourseCurriculumEditorState extends State<_CourseCurriculumEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _courseId;
  late String _title;
  late String _description;
  late DateTime _baseUpdatedAt;
  late List<_LessonDraft> _lessons;
  final Set<Key> _uploadingVideoKeys = {};
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _courseId = record.course.id;
    _title = record.course.title;
    _description = record.course.description;
    _baseUpdatedAt = record.updatedAt;
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

  Future<void> _pickLessonVideo(int index) async {
    final lesson = _lessons[index];
    if (_uploadingVideoKeys.contains(lesson.key)) return;
    final adminService = context.dependencies.adminService;

    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 30),
    );
    if (picked == null || !mounted) return;
    final contentType = _contentTypeForVideo(picked);
    if (contentType == null) {
      showErrorSnack(
        context,
        'Aina ya video haikubaliki. Tumia MP4, MOV au WEBM.',
      );
      return;
    }

    setState(() => _uploadingVideoKeys.add(lesson.key));
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxVideoBytes) {
        if (!mounted) return;
        showErrorSnack(
          context,
          'Video ni kubwa kuliko MB 200. Punguza ubora kisha jaribu tena.',
        );
        return;
      }
      final videoPath = await adminService.uploadLessonVideo(
        bytes: bytes,
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() {
        lesson.videoPath = videoPath;
        // An upload supersedes any pasted link so the two can never disagree.
        lesson.videoUrl = '';
        lesson.type = LessonType.video;
      });
      showSuccessSnack(context, 'Video imepakiwa. Hifadhi kozi kukamilisha.');
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: () => _pickLessonVideo(index),
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Imeshindikana kupakia video. Jaribu tena.');
    } finally {
      if (mounted) {
        setState(() => _uploadingVideoKeys.remove(lesson.key));
      }
    }
  }

  void _removeLessonVideo(int index) {
    AppFeedback.tap();
    setState(() => _lessons[index].videoPath = null);
  }

  void _save({required String status}) {
    if (_uploadingVideoKeys.isNotEmpty) {
      AppFeedback.error();
      showErrorSnack(
          context, 'Subiri video imalize kupakiwa kabla ya kuhifadhi.');
      return;
    }
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
    // Fields scrolled out of the lazy ListView are unmounted, so
    // `validate()` above cannot see them. Re-check the course-level values
    // here so the admin gets a Swahili error instead of a server rejection.
    final courseError = _firstCourseError();
    if (courseError != null) {
      AppFeedback.error();
      showErrorSnack(context, courseError);
      return;
    }
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
      // Only a brand new code is normalised. An existing course keeps its
      // stored code verbatim: upper-casing it here addressed a different
      // course row, which created a duplicate on the JSON store and failed
      // outright on the structured store.
      id: widget.isNew
          ? _courseId.trim().toUpperCase()
          : widget.record.course.id,
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
            videoPath: draft.videoPath,
            isLearnerVisible: draft.isLearnerVisible,
            readinessReasons: draft.readinessReasons,
          ),
      ],
    );
    AppFeedback.tap();
    Navigator.of(context).pop(
      _CourseEditResult(
        course: course,
        status: status,
        baseUpdatedAt: widget.isNew ? null : _baseUpdatedAt,
      ),
    );
  }

  String? _firstCourseError() {
    if (widget.isNew) {
      final code = _courseId.trim().toUpperCase();
      if (!RegExp(r'^[A-Z0-9][A-Z0-9-]{2,49}$').hasMatch(code)) {
        return 'Msimbo wa kozi unahitaji herufi kubwa, namba au vistari; '
            'tarakimu 3–50.';
      }
    }
    if (_title.trim().isEmpty) return 'Jina la kozi haliwezi kuwa tupu.';
    if (_description.trim().isEmpty) {
      return 'Maelezo ya kozi hayawezi kuwa tupu.';
    }
    return null;
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
      if (lesson.type == LessonType.video &&
          lesson.videoPath == null &&
          lesson.videoUrl.trim().isEmpty) {
        return 'Somo la $number linahitaji video iliyopakiwa au kiungo.';
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
        title: Text(widget.isNew ? 'Kozi mpya' : 'Hariri mtaala'),
        actions: [
          TextButton.icon(
            onPressed: () => _save(status: 'draft'),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Hifadhi rasimu'),
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
              if (widget.isNew) ...[
                TextFormField(
                  initialValue: _courseId,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Msimbo wa kozi',
                    helperText: 'Mfano: CRS-MAH-01',
                  ),
                  validator: (value) {
                    final code = value?.trim().toUpperCase() ?? '';
                    return RegExp(r'^[A-Z0-9][A-Z0-9-]{2,49}$').hasMatch(code)
                        ? null
                        : 'Tumia herufi kubwa, namba au vistari; tarakimu 3–50.';
                  },
                  onChanged: (value) => _courseId = value,
                  onSaved: (value) => _courseId = value ?? '',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // `onChanged` is what actually persists these two fields. The
              // enclosing ListView builds lazily, so scrolling down to the
              // lessons unmounts them; `FormState.save()` then never reaches
              // their `onSaved` and the editor would post the values captured
              // in initState ('' for a new course).
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Jina la kozi'),
                validator: _requiredField('Jina haliwezi kuwa tupu.'),
                onChanged: (value) => _title = value,
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
                onChanged: (value) => _description = value,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDecorations.pastelPanel(
                  context,
                  context.colors.surfacePeach,
                ),
                child: const Text(
                  'Wewe ndiye mwandishi na mchapishaji. Hifadhi rasimu kama '
                  'bado unaendelea, au chapisha kozi moja kwa moja ikiwa '
                  'maudhui yako tayari.',
                ),
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
                'Buruta kadi kubadilisha mpangilio. Ukichapisha, kozi yote '
                'itaonekana kwa wanafunzi mara moja.',
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
                    isUploadingVideo: _uploadingVideoKeys.contains(lesson.key),
                    onPickVideo: () => _pickLessonVideo(index),
                    onRemoveVideo: () => _removeLessonVideo(index),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _save(status: 'draft'),
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Hifadhi rasimu'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _save(status: 'approved'),
                      icon: const Icon(Icons.publish_outlined),
                      label: const Text('Chapisha kozi'),
                    ),
                  ),
                ],
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
    required this.isUploadingVideo,
    required this.onPickVideo,
    required this.onRemoveVideo,
    required this.onRemove,
    required this.onModuleTitleChanged,
    required this.onTypeChanged,
  });

  final int index;
  final _LessonDraft lesson;
  final bool isUploadingVideo;
  final VoidCallback onPickVideo;
  final VoidCallback onRemoveVideo;
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
          if (lesson.type == LessonType.video) ...[
            const SizedBox(height: AppSpacing.md),
            _LessonVideoField(
              lesson: lesson,
              isUploading: isUploadingVideo,
              onPickVideo: onPickVideo,
              onRemoveVideo: onRemoveVideo,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('video-url-${lesson.key}-${lesson.videoPath}'),
            initialValue: lesson.videoUrl,
            keyboardType: TextInputType.url,
            enabled: lesson.videoPath == null,
            decoration: InputDecoration(
              labelText: lesson.videoPath == null
                  ? 'Kiungo cha video (hiari kwa video iliyohifadhiwa)'
                  : 'Kiungo cha video (hakitumiki — video imepakiwa)',
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
            const SizedBox(height: AppSpacing.md),
          ],
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

/// Matches the bucket's file_size_limit and the project's dashboard-only
/// Global file size limit (Project Settings > Storage), which must be raised
/// to the same value or this check passes locally and still fails on upload.
/// Checking here avoids uploading most of an oversized file only to have it
/// rejected at the very end.
const _maxVideoBytes = 200 * 1024 * 1024;

String? _contentTypeForVideo(XFile file) {
  final declared = file.mimeType?.toLowerCase();
  if (declared != null && _supportedVideoTypes.contains(declared)) {
    return declared;
  }
  // Android's gallery picker frequently reports no MIME type, so fall back to
  // the file extension.
  return switch (file.name.toLowerCase().split('.').last) {
    'mp4' || 'm4v' => 'video/mp4',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    _ => null,
  };
}

const _supportedVideoTypes = {
  'video/mp4',
  'video/quicktime',
  'video/webm',
};

class _LessonVideoField extends StatelessWidget {
  const _LessonVideoField({
    required this.lesson,
    required this.isUploading,
    required this.onPickVideo,
    required this.onRemoveVideo,
  });

  final _LessonDraft lesson;
  final bool isUploading;
  final VoidCallback onPickVideo;
  final VoidCallback onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    if (isUploading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.pastelPanel(
          context,
          context.colors.surfaceMuted,
        ),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Inapakia video... usifunge ukurasa huu.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final videoPath = lesson.videoPath;
    if (videoPath == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPickVideo,
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Pakia video ya somo'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.pastelPanel(
        context,
        context.colors.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Video imepakiwa',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            videoPath.split('/').last,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.muted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onPickVideo,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Badilisha'),
              ),
              TextButton.icon(
                onPressed: onRemoveVideo,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Ondoa video'),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    final dependencies = context.dependencies;
    final adminService = dependencies.adminService;
    final result = await _showCourseEditor(
      context: context,
      record: record,
    );
    if (result == null) return;
    try {
      await adminService.upsertContentCourse(
        course: result.course,
        status: result.status,
        baseUpdatedAt: result.baseUpdatedAt,
      );
      await dependencies.refreshCatalog();
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

  Future<void> _createCourse() async {
    final dependencies = context.dependencies;
    final adminService = dependencies.adminService;
    final now = DateTime.now();
    final record = AdminContentCourseRecord(
      id: 'CRS-',
      status: 'draft',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      course: Course(
        id: 'CRS-',
        title: '',
        description: '',
        badge: 'Kozi ya maandishi',
        icon: Icons.menu_book_outlined,
        progress: 0,
        imageUrl: 'assets/images/courses/nyanya.jpg',
        outcomes: const ['Sehemu mpya'],
        lessons: [
          Lesson(
            moduleKey: 'new-${now.microsecondsSinceEpoch}',
            moduleTitle: 'Sehemu mpya',
            title: '',
            type: LessonType.reading,
            meta: 'Dakika 5',
            description: '',
            durationMinutes: 5,
            isLearnerVisible: false,
            readinessReasons: const [],
          ),
        ],
      ),
    );
    final result = await _showCourseEditor(
      context: context,
      record: record,
      isNew: true,
    );
    if (result == null) return;
    try {
      await adminService.upsertContentCourse(
        course: result.course,
        status: result.status,
        createOnly: true,
      );
      await dependencies.refreshCatalog();
      if (!mounted) return;
      showSuccessSnack(
        context,
        result.status == 'approved'
            ? 'Kozi imechapishwa na sasa inaonekana kwa wanafunzi.'
            : 'Kozi imehifadhiwa kama rasimu.',
      );
      _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        error.message,
        actionLabel: 'Jaribu tena',
        onAction: _createCourse,
      );
    }
  }

  Future<void> _editDocument(AdminContentDocumentRecord record) async {
    final dependencies = context.dependencies;
    final adminService = dependencies.adminService;
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
      await dependencies.refreshCatalog();
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _AdminSectionHeader(
            title: 'Kozi',
            count: _courses.length,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _createCourse,
              icon: const Icon(Icons.add),
              label: const Text('Ongeza kozi na mtaala'),
            ),
          ),
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
                  child: Builder(
                    builder: (context) {
                      void openEditor() {
                        AppFeedback.tap();
                        _editCourse(record);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            onTap: openEditor,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${record.course.lessons.length} masomo'
                                    '${record.course.lessons.any((lesson) => lesson.type == LessonType.video) ? ' · Ina video' : ''}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _AdminStatusPill(status: record.status),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Hariri kozi',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: openEditor,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.sm,
                            ),
                            child: FilledButton.tonalIcon(
                              onPressed: openEditor,
                              icon: const Icon(Icons.menu_book_outlined),
                              label: const Text('Hariri maudhui na mtaala'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      );
                    },
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
  final Set<String> _grantingAccessUserIds = <String>{};

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

  Future<void> _grantPaidAccess(AdminUserSummary user) async {
    if (_grantingAccessUserIds.contains(user.id)) return;
    final adminService = context.dependencies.adminService;

    List<AdminPlan> plans;
    try {
      plans = await adminService.listPlans();
    } on AdminException catch (error) {
      if (mounted) showErrorSnack(context, error.message);
      return;
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Imeshindikana kupakia vifurushi.');
      return;
    }
    if (!mounted) return;
    if (plans.isEmpty) {
      showErrorSnack(context, 'Hakuna kifurushi kinachopatikana.');
      return;
    }

    final grant = await _showPaidAccessGrantSheet(
      context: context,
      user: user,
      plans: plans,
    );
    if (grant == null || !mounted) return;

    setState(() => _grantingAccessUserIds.add(user.id));
    AdminPaymentRecord? recordedPayment;
    try {
      recordedPayment = await adminService.recordPayment(
        userId: user.id,
        planId: grant.plan.id,
        method: grant.method,
        amountTzs: grant.plan.priceTzs,
        reference: grant.reference,
        note: grant.note,
      );
      await adminService.approvePayment(recordedPayment.id);
      if (!mounted) return;
      AppFeedback.success();
      showSuccessSnack(
        context,
        'Malipo yamethibitishwa na mafunzo yamefunguliwa.',
      );
      await _load();
    } on AdminException catch (error) {
      if (!mounted) return;
      final prefix = recordedPayment == null
          ? ''
          : 'Malipo yamerekodiwa lakini ufikiaji haujafunguliwa. '
              'Kamilisha idhini kwenye kichupo cha Malipo. ';
      showErrorSnack(context, '$prefix${error.message}');
    } catch (_) {
      if (!mounted) return;
      final message = recordedPayment == null
          ? 'Imeshindikana kuthibitisha malipo.'
          : 'Malipo yamerekodiwa lakini ufikiaji haujafunguliwa. '
              'Kamilisha idhini kwenye kichupo cha Malipo.';
      showErrorSnack(context, message);
    } finally {
      if (mounted) {
        setState(() => _grantingAccessUserIds.remove(user.id));
      }
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
          final user = _page.users[index - _headerSlotCount];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _AdminUserCard(
              user: user,
              isGrantingAccess: _grantingAccessUserIds.contains(user.id),
              onGrantPaidAccess:
                  user.role == 'admin' || user.accountStatus == 'active'
                      ? null
                      : () => _grantPaidAccess(user),
            ),
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
          labelText: 'Tafuta kwa barua pepe au jina',
          hintText: 'Mfano: asha@barua.com au Asha',
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

class _PaidAccessGrant {
  const _PaidAccessGrant({
    required this.plan,
    required this.method,
    required this.reference,
    required this.note,
  });

  final AdminPlan plan;
  final String method;
  final String? reference;
  final String? note;
}

Future<_PaidAccessGrant?> _showPaidAccessGrantSheet({
  required BuildContext context,
  required AdminUserSummary user,
  required List<AdminPlan> plans,
}) async {
  final referenceController = TextEditingController();
  final noteController = TextEditingController();
  var selectedPlan = plans.first;
  var method = 'cash';

  try {
    return await showModalBottomSheet<_PaidAccessGrant>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thibitisha malipo na fungua mafunzo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user.email ?? user.id,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<AdminPlan>(
                      initialValue: selectedPlan,
                      decoration: const InputDecoration(labelText: 'Kifurushi'),
                      items: [
                        for (final plan in plans)
                          DropdownMenuItem(
                            value: plan,
                            child: Text('${plan.title} — ${plan.price}'),
                          ),
                      ],
                      onChanged: (plan) {
                        if (plan != null) {
                          setSheetState(() => selectedPlan = plan);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('Fedha Taslimu'),
                          selected: method == 'cash',
                          onSelected: (_) =>
                              setSheetState(() => method = 'cash'),
                        ),
                        ChoiceChip(
                          label: const Text('Uhamisho wa Benki'),
                          selected: method == 'bank_transfer',
                          onSelected: (_) =>
                              setSheetState(() => method = 'bank_transfer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Namba ya risiti (hiari)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Maelezo (hiari)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final reference = referenceController.text.trim();
                          final note = noteController.text.trim();
                          Navigator.of(sheetContext).pop(
                            _PaidAccessGrant(
                              plan: selectedPlan,
                              method: method,
                              reference: reference.isEmpty ? null : reference,
                              note: note.isEmpty ? null : note,
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Thibitisha na Fungua'),
                      ),
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
    referenceController.dispose();
    noteController.dispose();
  }
}

/// Records cash/bank-transfer payments and approves/reverses them. The user
/// cards offer the same audited record-then-approve flow as a one-step staff
/// action; learner-facing screens never accept a payment themselves (see
/// PaywallScreen). Sales happen through AJE's existing cash/bank-transfer
/// process, and staff confirm them in the admin dashboard.
class _AdminPaymentsTab extends StatefulWidget {
  const _AdminPaymentsTab();

  @override
  State<_AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<_AdminPaymentsTab> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  bool _didRequestInitialLoad = false;
  bool _loadingPlans = true;
  bool _loadingPayments = true;
  bool _searching = false;
  bool _submitting = false;

  List<AdminPlan> _plans = const [];
  AdminPlan? _selectedPlan;
  String _method = 'cash';
  List<AdminUserSummary> _searchResults = const [];
  AdminUserSummary? _selectedLearner;
  AdminPaymentsPage _pendingPayments =
      const AdminPaymentsPage(total: 0, records: []);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestInitialLoad) return;
    _didRequestInitialLoad = true;
    _loadPlans();
    _loadPendingPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _loadingPlans = true);
    try {
      final plans = await context.dependencies.adminService.listPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selectedPlan ??= plans.isEmpty ? null : plans.first;
        _amountController.text = _selectedPlan?.priceTzs.toString() ?? '';
        _loadingPlans = false;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() => _loadingPlans = false);
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlans = false);
      showErrorSnack(context, 'Imeshindikana kupakia vifurushi.');
    }
  }

  Future<void> _loadPendingPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final page = await context.dependencies.adminService.listPayments(
        status: 'pending',
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _pendingPayments = page;
        _loadingPayments = false;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() => _loadingPayments = false);
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPayments = false);
      showErrorSnack(context, 'Imeshindikana kupakia malipo yanayosubiri.');
    }
  }

  Future<void> _searchLearner() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    try {
      final page = await context.dependencies.adminService.listUsers(
        search: query,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = page.users;
        _searching = false;
      });
    } on AdminException catch (error) {
      if (!mounted) return;
      setState(() => _searching = false);
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
      showErrorSnack(context, 'Imeshindikana kutafuta mtumiaji.');
    }
  }

  Future<void> _recordPayment() async {
    final learner = _selectedLearner;
    final plan = _selectedPlan;
    final amount = int.tryParse(_amountController.text.trim());
    if (learner == null) {
      showSnack(context, 'Chagua mkulima kwanza.');
      return;
    }
    if (plan == null) {
      showSnack(context, 'Chagua kifurushi.');
      return;
    }
    if (amount == null || amount < 0) {
      showSnack(context, 'Weka kiasi sahihi cha malipo.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.dependencies.adminService.recordPayment(
        userId: learner.id,
        planId: plan.id,
        method: _method,
        amountTzs: amount,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      AppFeedback.success();
      showSuccessSnack(context, 'Malipo yamerekodiwa. Yanasubiri idhini.');
      setState(() {
        _selectedLearner = null;
        _searchController.clear();
        _searchResults = const [];
        _referenceController.clear();
        _noteController.clear();
      });
      await _loadPendingPayments();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Imeshindikana kurekodi malipo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _approve(AdminPaymentRecord record) async {
    final confirmed = await confirmAction(
      context,
      title: 'Idhinisha malipo?',
      message:
          '${record.userEmail ?? record.userId} atapata ufikiaji mara moja.',
      confirmLabel: 'Idhinisha',
    );
    if (!confirmed || !mounted) return;
    try {
      await context.dependencies.adminService.approvePayment(record.id);
      if (!mounted) return;
      AppFeedback.success();
      showSuccessSnack(context, 'Malipo yameidhinishwa.');
      await _loadPendingPayments();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Imeshindikana kuidhinisha malipo.');
    }
  }

  Future<void> _reverse(AdminPaymentRecord record) async {
    final confirmed = await confirmAction(
      context,
      title: 'Rudisha nyuma malipo?',
      message: 'Ufikiaji wa ${record.userEmail ?? record.userId} utasitishwa.',
      confirmLabel: 'Rudisha Nyuma',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.dependencies.adminService.reversePayment(record.id);
      if (!mounted) return;
      showSnack(context, 'Malipo yamerudishwa nyuma.');
      await _loadPendingPayments();
    } on AdminException catch (error) {
      if (!mounted) return;
      showErrorSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Imeshindikana kurudisha malipo nyuma.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadPlans(), _loadPendingPayments()]);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Rekodi Malipo Mapya',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedLearner == null) ...[
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Tafuta mkulima kwa barua pepe',
                        hintText: 'Mfano: asha@barua.com',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.sm),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Tafuta',
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _searchLearner,
                              ),
                      ),
                      onSubmitted: (_) => _searchLearner(),
                    ),
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      for (final user in _searchResults)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(user.email ?? user.id),
                          subtitle:
                              Text(_accountStatusLabel(user.accountStatus)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            AppFeedback.tap();
                            setState(() {
                              _selectedLearner = user;
                              _searchResults = const [];
                            });
                          },
                        ),
                    ],
                  ] else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person),
                      title:
                          Text(_selectedLearner!.email ?? _selectedLearner!.id),
                      subtitle: Text(
                        _accountStatusLabel(_selectedLearner!.accountStatus),
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            setState(() => _selectedLearner = null),
                        child: const Text('Badilisha'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_loadingPlans)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<AdminPlan>(
                        initialValue: _selectedPlan,
                        decoration: const InputDecoration(
                          labelText: 'Kifurushi',
                        ),
                        items: [
                          for (final plan in _plans)
                            DropdownMenuItem(
                              value: plan,
                              child: Text('${plan.title} — ${plan.price}'),
                            ),
                        ],
                        onChanged: (plan) {
                          setState(() {
                            _selectedPlan = plan;
                            _amountController.text =
                                plan?.priceTzs.toString() ?? '';
                          });
                        },
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('Fedha Taslimu'),
                          selected: _method == 'cash',
                          onSelected: (_) => setState(() => _method = 'cash'),
                        ),
                        ChoiceChip(
                          label: const Text('Uhamisho wa Benki'),
                          selected: _method == 'bank_transfer',
                          onSelected: (_) =>
                              setState(() => _method = 'bank_transfer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _amountController,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kiasi (TZS)',
                        helperText:
                            'Kiasi kinawekwa na kifurushi kilichochaguliwa.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Namba ya risiti (hiari)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Maelezo (hiari)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting
                            ? null
                            : () {
                                AppFeedback.tap();
                                _recordPayment();
                              },
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_card_outlined),
                        label: const Text('Rekodi Malipo'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _AdminSectionHeader(
            title: 'Malipo Yanayosubiri',
            count: _pendingPayments.total,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingPayments)
            const Center(child: CircularProgressIndicator())
          else if (_pendingPayments.records.isEmpty)
            const EmptyState(
              icon: Icons.payments_outlined,
              title: 'Hakuna malipo yanayosubiri',
              body: 'Malipo mapya yataonekana hapa yakisubiri idhini.',
            )
          else
            for (final record in _pendingPayments.records)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.userEmail ?? record.userId,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${record.planId} · ${record.method == 'cash' ? 'Fedha Taslimu' : 'Uhamisho wa Benki'} · '
                          '${record.currency} ${record.amountTzs}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.colors.muted,
                                  ),
                        ),
                        if (record.reference != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Risiti: ${record.reference}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _reverse(record),
                                child: const Text('Rudisha Nyuma'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _approve(record),
                                child: const Text('Idhinisha'),
                              ),
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

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.isGrantingAccess,
    required this.onGrantPaidAccess,
  });

  final AdminUserSummary user;
  final bool isGrantingAccess;
  final VoidCallback? onGrantPaidAccess;

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email ?? 'Mtumiaji');
    final roleLabel = user.role == 'admin' ? 'Admin' : 'Mkulima';
    final planLabel = user.subscriptionPlan ?? 'Hakuna kifurushi';
    final accessLabel = user.role == 'admin'
        ? 'Ufikiaji wa Admin'
        : _accountStatusLabel(user.accountStatus);
    final hasEffectiveAccess =
        user.role == 'admin' || user.accountStatus == 'active';

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
                          user.displayName!.trim().isNotEmpty &&
                          user.email != null)
                        Text(
                          user.email!,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kifurushi: $planLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.muted,
                        ),
                  ),
                ),
                Pill(
                  label: accessLabel,
                  color: hasEffectiveAccess
                      ? context.colors.successSurface
                      : user.accountStatus == 'suspended'
                          ? context.colors.error.withValues(alpha: 0.12)
                          : context.colors.surfacePeach,
                ),
              ],
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
            if (onGrantPaidAccess != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isGrantingAccess ? null : onGrantPaidAccess,
                  icon: isGrantingAccess
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: const Text('Thibitisha Malipo'),
                ),
              ),
            ],
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

String _accountStatusLabel(String accountStatus) {
  return switch (accountStatus) {
    'active' => 'Amewashwa',
    'suspended' => 'Amesitishwa',
    _ => 'Inasubiri',
  };
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
    required this.baseUpdatedAt,
  });

  final Course course;
  final String status;
  final DateTime? baseUpdatedAt;
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
    this.videoPath,
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
      videoPath: lesson.videoPath,
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
  String? videoPath;
  bool isLearnerVisible;
  List<String> readinessReasons;
}
