// Regression tests for the admin curriculum editor bugs found during the
// 0.1.6-build7 emulator QA pass:
//
//  1. "Course title is required." when creating a course — the course title and
//     description fields only wrote back through `onSaved`, and the enclosing
//     lazy ListView unmounts them once the admin scrolls down to the lessons.
//     `FormState.save()` then never reaches them, so the editor posted the
//     values captured in `initState` ('' for a new course).
//  2. Editing an existing course whose code is not already upper case created a
//     duplicate course, because the editor upper-cased the id on every save
//     rather than only when minting a new one.

import 'dart:typed_data';

import 'package:aje_farms_mobile/src/app/app_dependencies.dart';
import 'package:aje_farms_mobile/src/features/admin/admin_dashboard_screen.dart';
import 'package:aje_farms_mobile/src/models/admin_models.dart';
import 'package:aje_farms_mobile/src/models/app_document.dart';
import 'package:aje_farms_mobile/src/models/community_post.dart';
import 'package:aje_farms_mobile/src/models/community_topics.dart';
import 'package:aje_farms_mobile/src/models/course.dart';
import 'package:aje_farms_mobile/src/models/home_topics.dart';
import 'package:aje_farms_mobile/src/services/admin_service.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:aje_farms_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('admin can rename learner home topics', (tester) async {
    final adminService = _RecordingAdminService(courses: const []);
    var refreshCount = 0;
    await _pumpAdminContent(
      tester,
      adminService,
      refreshCatalog: () async {
        refreshCount++;
      },
    );

    await tester.tap(find.text('Hariri mada za utafutaji'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mada ya 1'),
      'Mazao ya Biashara',
    );
    await tester.tap(find.text('Hifadhi mada'));
    await tester.pumpAndSettle();

    expect(adminService.homeTopics.first, 'Mazao ya Biashara');
    expect(adminService.homeTopics, hasLength(4));
    expect(refreshCount, 1);
    expect(find.textContaining('Mazao ya Biashara'), findsOneWidget);
  });

  testWidgets('admin can add, reorder, and remove learner home topics',
      (tester) async {
    final adminService = _RecordingAdminService(courses: const []);
    await _pumpAdminContent(
      tester,
      adminService,
      refreshCatalog: () async {},
    );

    await tester.tap(find.text('Hariri mada za utafutaji'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ongeza mada'));
    await tester.tap(find.text('Ongeza mada'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mada ya 5'),
      'Teknolojia',
    );
    await tester.tap(find.byTooltip('Hamisha mada ya 5 juu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hifadhi mada'));
    await tester.pumpAndSettle();

    expect(adminService.homeTopics, hasLength(5));
    expect(adminService.homeTopics[3], 'Teknolojia');

    await tester.tap(find.text('Hariri mada za utafutaji'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mada ya 4'),
      'Nafaka',
    );
    await tester.tap(find.text('Hifadhi mada'));
    await tester.pumpAndSettle();
    expect(find.text('Kila mada lazima iwe tofauti.'), findsNWidgets(2));

    final deleteFourth = find.byTooltip('Ondoa mada ya 4');
    await tester.ensureVisible(deleteFourth);
    await tester.pumpAndSettle();
    await tester.tap(deleteFourth);
    await tester.pumpAndSettle();
    expect(find.text('Kila mada lazima iwe tofauti.'), findsNothing);
    await tester.tap(find.text('Hifadhi mada'));
    await tester.pumpAndSettle();

    expect(adminService.homeTopics, hasLength(4));
    expect(adminService.homeTopics, isNot(contains('Teknolojia')));
  });

  testWidgets('admin can change community topics', (tester) async {
    final adminService = _RecordingAdminService(courses: const []);
    await _pumpAdminContent(
      tester,
      adminService,
      refreshCatalog: () async {},
    );

    final editCommunityTopics = find.text('Hariri mada za jamii');
    for (var attempt = 0;
        attempt < 10 && editCommunityTopics.evaluate().isEmpty;
        attempt++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(editCommunityTopics, findsOneWidget);
    await tester.tap(editCommunityTopics);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mada ya 1'),
      'Matunda',
    );
    await tester.tap(find.text('Hifadhi mada'));
    await tester.pumpAndSettle();

    expect(adminService.communityTopics.first, 'Matunda');
  });

  testWidgets(
    'book editor disposes safely when its route starts dismissing',
    (tester) async {
      final document = AdminContentDocumentRecord(
        id: 'document-1',
        status: 'approved',
        updatedAt: DateTime.utc(2026, 8, 12),
        document: const AppDocument(
          id: 'document-1',
          title: 'Kitabu cha majaribio',
          courseId: 'course-1',
          courseTitle: 'Kozi ya majaribio',
          description: 'Maelezo ya kitabu.',
          type: 'PDF',
          sizeLabel: '1 MB',
          url: 'https://example.test/book.pdf',
        ),
      );
      final adminService = _RecordingAdminService(
        courses: const [],
        documents: [document],
      );
      await _pumpAdminContent(tester, adminService);

      await tester.scrollUntilVisible(
        find.byTooltip('Hariri document'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      final editDocumentButton =
          find.widgetWithIcon(IconButton, Icons.edit_outlined);
      tester.widget<IconButton>(editDocumentButton).onPressed!();
      await tester.pumpAndSettle();

      final sheetContext = tester.element(find.text('Hariri content'));
      Navigator.of(sheetContext).pop();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dashibodi ya Admin'), findsOneWidget);
      expect(adminService.lastUpsertedDocument, isNull);
    },
  );

  testWidgets('topic backend failures are shown instead of hardcoded settings',
      (tester) async {
    final adminService = _RecordingAdminService(
      courses: const [],
      failHomeTopics: true,
    );

    await _pumpAdminContent(tester, adminService);

    expect(find.text('not available'), findsOneWidget);
    expect(find.text('Ongeza kozi na mtaala'), findsOneWidget);
    expect(find.text('Hariri mada za utafutaji'), findsOneWidget);
    final editButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Hariri mada za utafutaji'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(editButton.onPressed, isNull);
    expect(find.textContaining('Matunda na Mbogamboga'), findsNothing);
  });

  testWidgets(
    'new course keeps the typed title after scrolling down to the lessons',
    (tester) async {
      final adminService = _RecordingAdminService(courses: const []);
      await _pumpAdminContent(tester, adminService);

      await tester.tap(find.text('Ongeza kozi na mtaala'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Msimbo wa kozi'),
        'CRS-TEST-01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Jina la kozi'),
        'Kozi ya Majaribio',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Maelezo ya kozi'),
        'Maelezo ya kozi ya majaribio',
      );
      await tester.pumpAndSettle();

      // Fill the seeded lesson. Reaching it scrolls the course-level fields out
      // of the lazily built ListView — this is the step that used to discard
      // the title and description.
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Jina la somo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Jina la somo'),
        'Somo la kwanza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Maandishi ya somo'),
        'Maandishi ya somo la kwanza',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi rasimu'));
      await tester.pumpAndSettle();

      final saved = adminService.lastUpsertedCourse;
      expect(saved, isNotNull, reason: 'Save never reached the admin service.');
      expect(saved!.title, 'Kozi ya Majaribio');
      expect(saved.description, 'Maelezo ya kozi ya majaribio');
      expect(saved.id, 'CRS-TEST-01');
    },
  );

  testWidgets(
    'trusted admin can publish a new course in one editor submission',
    (tester) async {
      final adminService = _RecordingAdminService(courses: const []);
      var catalogRefreshes = 0;
      await _pumpAdminContent(
        tester,
        adminService,
        refreshCatalog: () async => catalogRefreshes += 1,
      );

      await tester.tap(find.text('Ongeza kozi na mtaala'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Msimbo wa kozi'),
        'CRS-PUBLISH-01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Jina la kozi'),
        'Kozi ya Kuchapisha',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Maelezo ya kozi'),
        'Kozi ya AJE inayochapishwa moja kwa moja.',
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Jina la somo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Jina la somo'),
        'Somo la kwanza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Maandishi ya somo'),
        'Maudhui yaliyoandikwa na msimamizi wa AJE.',
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Chapisha kozi'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Chapisha kozi'));
      await tester.pumpAndSettle();

      expect(adminService.lastUpsertedCourse?.id, 'CRS-PUBLISH-01');
      expect(adminService.lastUpsertedStatus, 'approved');
      expect(adminService.lastCreateOnly, true);
      expect(
        catalogRefreshes,
        1,
        reason: 'Publishing must invalidate the learner-facing catalog.',
      );
    },
  );

  testWidgets(
    'editing an existing course keeps its course code verbatim',
    (tester) async {
      final record = _courseRecord(id: 'pasheni', title: 'Kilimo cha Pasheni');
      final adminService = _RecordingAdminService(courses: [record]);
      await _pumpAdminContent(tester, adminService);

      await tester.tap(find.text('Hariri maudhui na mtaala').first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi rasimu'));
      await tester.pumpAndSettle();

      final saved = adminService.lastUpsertedCourse;
      expect(saved, isNotNull, reason: 'Save never reached the admin service.');
      expect(
        saved!.id,
        'pasheni',
        reason: 'Upper-casing the code writes to a different course row.',
      );
    },
  );

  testWidgets(
    'editing an existing course keeps a retyped title after scrolling',
    (tester) async {
      final record = _courseRecord(id: 'CRS-PSH-01', title: 'Jina la Zamani');
      final adminService = _RecordingAdminService(courses: [record]);
      await _pumpAdminContent(tester, adminService);

      await tester.tap(find.text('Hariri maudhui na mtaala').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Jina la kozi'),
        'Jina Jipya la Kozi',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Jina la somo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi rasimu'));
      await tester.pumpAndSettle();

      expect(adminService.lastUpsertedCourse?.title, 'Jina Jipya la Kozi');
    },
  );

  testWidgets(
    'an already uploaded lesson video survives a save untouched',
    (tester) async {
      final record = _courseRecord(
        id: 'CRS-VID-01',
        title: 'Kozi ya Video',
        lesson: const Lesson(
          id: 'lesson-1',
          moduleId: 'module-1',
          moduleTitle: 'Sehemu ya video',
          title: 'Somo la video',
          type: LessonType.video,
          meta: 'Dakika 5',
          description: '',
          durationMinutes: 5,
          videoPath: 'lesson-videos/vid-existing.mp4',
        ),
      );
      final adminService = _RecordingAdminService(courses: [record]);
      await _pumpAdminContent(tester, adminService);

      await tester.tap(find.text('Hariri maudhui na mtaala').first);
      await tester.pumpAndSettle();

      // The upload is surfaced, and the paste-a-link field steps aside so the
      // two sources cannot disagree.
      expect(find.text('Video imepakiwa'), findsOneWidget);
      expect(find.text('vid-existing.mp4'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi rasimu'));
      await tester.pumpAndSettle();

      final saved = adminService.lastUpsertedCourse;
      expect(saved, isNotNull);
      expect(saved!.lessons.single.videoPath, 'lesson-videos/vid-existing.mp4');
      expect(saved.lessons.single.resourceUrl, isNull);
    },
  );

  testWidgets(
    'a video lesson with neither an upload nor a link is refused',
    (tester) async {
      final record = _courseRecord(
        id: 'CRS-VID-02',
        title: 'Kozi ya Video',
        lesson: const Lesson(
          id: 'lesson-1',
          moduleId: 'module-1',
          moduleTitle: 'Sehemu ya video',
          title: 'Somo la video',
          type: LessonType.video,
          meta: 'Dakika 5',
          description: '',
          durationMinutes: 5,
        ),
      );
      final adminService = _RecordingAdminService(courses: [record]);
      await _pumpAdminContent(tester, adminService);

      await tester.tap(find.text('Hariri maudhui na mtaala').first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi rasimu'));
      await tester.pumpAndSettle();

      expect(adminService.lastUpsertedCourse, isNull);
      expect(
        find.textContaining('inahitaji video iliyopakiwa au kiungo'),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpAdminContent(WidgetTester tester, AdminService adminService,
    {Future<void> Function()? refreshCatalog}) async {
  final session = AppSessionController();
  await session.signInWithEmail('admin@aje.test', role: 'admin');
  final dependencies = AppDependencies.demo().copyWith(
    adminService: adminService,
    refreshCatalog: refreshCatalog,
  );

  await tester.pumpWidget(
    AppSessionScope(
      controller: session,
      child: AppDependenciesScope(
        dependencies: dependencies,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AdminDashboardScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AdminContentCourseRecord _courseRecord({
  required String id,
  required String title,
  Lesson? lesson,
}) {
  return AdminContentCourseRecord(
    id: id,
    status: 'approved',
    updatedAt: DateTime.utc(2026, 7, 26, 14, 10, 26, 551),
    course: Course(
      id: id,
      title: title,
      description: 'Maelezo ya kozi iliyopo.',
      badge: 'Kozi ya maandishi',
      icon: Icons.menu_book,
      progress: 0,
      imageUrl: 'assets/images/courses/pasheni.jpg',
      outcomes: const ['Sehemu ya masomo'],
      lessons: [
        lesson ??
            const Lesson(
              id: 'lesson-1',
              moduleId: 'module-1',
              moduleTitle: 'Sehemu ya masomo',
              title: 'Kuchagua eneo la shamba',
              type: LessonType.reading,
              meta: 'Dakika 5',
              description: 'Chunguza mwanga, njia ya maji na nafasi.',
              durationMinutes: 5,
            ),
      ],
    ),
  );
}

class _RecordingAdminService implements AdminService {
  _RecordingAdminService({
    required this.courses,
    this.documents = const [],
    this.failHomeTopics = false,
  });

  final List<AdminContentCourseRecord> courses;
  final List<AdminContentDocumentRecord> documents;
  final bool failHomeTopics;
  Course? lastUpsertedCourse;
  AppDocument? lastUpsertedDocument;
  String? lastUpsertedStatus;
  bool? lastCreateOnly;
  String? uploadedVideoContentType;
  List<String> homeTopics = defaultHomeTopics;
  List<String> communityTopics = defaultCommunityTopics;

  @override
  Future<List<String>> getHomeTopics() async {
    if (failHomeTopics) throw const AdminException('not available');
    return homeTopics;
  }

  @override
  Future<List<String>> updateHomeTopics(List<String> topics) async {
    homeTopics = topics;
    return homeTopics;
  }

  @override
  Future<List<String>> getCommunityTopics() async => communityTopics;

  @override
  Future<List<String>> updateCommunityTopics(List<String> topics) async {
    communityTopics = topics;
    return communityTopics;
  }

  @override
  Future<List<AdminContentCourseRecord>> listContentCourses() async => courses;

  @override
  Future<AdminContentCourseRecord> upsertContentCourse({
    required Course course,
    required String status,
    DateTime? baseUpdatedAt,
    bool createOnly = false,
  }) async {
    lastUpsertedCourse = course;
    lastUpsertedStatus = status;
    lastCreateOnly = createOnly;
    return AdminContentCourseRecord(
      id: course.id,
      status: status,
      updatedAt: DateTime.now().toUtc(),
      course: course,
    );
  }

  @override
  Future<List<AdminSourceSegment>> searchSourceSegments({
    String search = '',
  }) async =>
      const [];

  @override
  Future<AdminLessonSourceReviewResult> approveLessonSource({
    required String lessonId,
    required String sourceSegmentId,
    required String evidenceNote,
    required String groundingFact,
  }) async {
    throw const AdminException('not used');
  }

  @override
  Future<AdminLessonSourceReviewResult> registerUploadedVideoEvidence({
    required String lessonId,
    required String transcript,
    required String evidenceNote,
    required String groundingFact,
  }) async {
    throw const AdminException('not used');
  }

  @override
  Future<String> uploadLessonVideo({
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedVideoContentType = contentType;
    return 'lesson-videos/vid-test.mp4';
  }

  @override
  Future<String> uploadContentMedia({
    required Uint8List bytes,
    required String contentType,
    required String kind,
  }) async =>
      'https://example.test/content-media/$kind-test';

  @override
  Future<List<AdminContentDocumentRecord>> listContentDocuments() async =>
      documents;

  @override
  Future<AdminContentDocumentRecord> upsertContentDocument({
    required AppDocument document,
    required String status,
  }) async {
    lastUpsertedDocument = document;
    return AdminContentDocumentRecord(
      id: document.id,
      status: status,
      document: document,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<AdminModerationReport>> listModerationReports() async => const [];

  @override
  Future<CommunityPost> resolveModerationReport({
    required String postId,
    required String action,
  }) async {
    throw const AdminException('not used');
  }

  @override
  Future<List<AdminAiReport>> listAiReports() async => const [];

  @override
  Future<void> resolveAiReport(String reportId, {String? note}) async {}

  @override
  Future<List<AdminAccountDeletionRequest>>
      listAccountDeletionRequests() async => const [];

  @override
  Future<void> resolveAccountDeletionRequest({
    required String requestId,
    required String status,
    String? note,
  }) async {}

  @override
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async =>
      const AdminUsersPage(total: 0, users: []);

  @override
  Future<void> updateUserAccess({
    required String userId,
    required String action,
    String? reason,
  }) async {}

  @override
  Future<List<AdminPlan>> listPlans() async => const [];

  @override
  Future<AdminPaymentsPage> listPayments({
    String? status,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async =>
      const AdminPaymentsPage(total: 0, records: []);

  @override
  Future<AdminPaymentRecord> recordPayment({
    required String userId,
    required String planId,
    required String method,
    required int amountTzs,
    String? reference,
    String? note,
  }) async {
    throw const AdminException('not used');
  }

  @override
  Future<AdminPaymentRecord> approvePayment(
    String paymentRecordId, {
    String? reason,
  }) async {
    throw const AdminException('not used');
  }

  @override
  Future<AdminPaymentRecord> reversePayment(
    String paymentRecordId, {
    String? reason,
  }) async {
    throw const AdminException('not used');
  }

  @override
  Future<List<AdminAuditEvent>> paymentAuditEvents(
    String paymentRecordId,
  ) async =>
      const [];
}
