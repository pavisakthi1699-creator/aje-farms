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
import 'package:aje_farms_mobile/src/models/course.dart';
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

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi'));
      await tester.pumpAndSettle();

      final saved = adminService.lastUpsertedCourse;
      expect(saved, isNotNull, reason: 'Save never reached the admin service.');
      expect(saved!.title, 'Kozi ya Majaribio');
      expect(saved.description, 'Maelezo ya kozi ya majaribio');
      expect(saved.id, 'CRS-TEST-01');
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

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi'));
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

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi'));
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

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi'));
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

      await tester.tap(find.widgetWithText(TextButton, 'Hifadhi'));
      await tester.pumpAndSettle();

      expect(adminService.lastUpsertedCourse, isNull);
      expect(
        find.textContaining('inahitaji video iliyopakiwa au kiungo'),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpAdminContent(
  WidgetTester tester,
  AdminService adminService,
) async {
  final session = AppSessionController();
  await session.signInWithEmail('admin@aje.test', role: 'admin');
  final dependencies =
      AppDependencies.demo().copyWith(adminService: adminService);

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
  _RecordingAdminService({required this.courses});

  final List<AdminContentCourseRecord> courses;
  Course? lastUpsertedCourse;
  String? uploadedVideoContentType;

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
  Future<String> uploadLessonVideo({
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedVideoContentType = contentType;
    return 'lesson-videos/vid-test.mp4';
  }

  @override
  Future<List<AdminContentDocumentRecord>> listContentDocuments() async =>
      const [];

  @override
  Future<AdminContentDocumentRecord> upsertContentDocument({
    required AppDocument document,
    required String status,
  }) async {
    throw const AdminException('not used');
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
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async =>
      const AdminUsersPage(total: 0, users: []);

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
