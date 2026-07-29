import 'dart:typed_data';

import '../models/admin_models.dart';
import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/course.dart';

abstract interface class AdminService {
  Future<List<AdminContentCourseRecord>> listContentCourses();
  Future<AdminContentCourseRecord> upsertContentCourse({
    required Course course,
    required String status,
    DateTime? baseUpdatedAt,
    bool createOnly = false,
  });
  Future<List<AdminSourceSegment>> searchSourceSegments({
    String search = '',
  });
  Future<AdminLessonSourceReviewResult> approveLessonSource({
    required String lessonId,
    required String sourceSegmentId,
    required String evidenceNote,
    required String groundingFact,
  });
  /// Uploads a lesson video and returns its storage key, which a lesson can
  /// then reference. The bytes go straight to storage through a short-lived
  /// signed URL rather than through the API.
  Future<String> uploadLessonVideo({
    required Uint8List bytes,
    required String contentType,
  });
  Future<List<AdminContentDocumentRecord>> listContentDocuments();
  Future<AdminContentDocumentRecord> upsertContentDocument({
    required AppDocument document,
    required String status,
  });
  Future<List<AdminModerationReport>> listModerationReports();
  Future<CommunityPost> resolveModerationReport({
    required String postId,
    required String action,
  });
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  });

  /// The server-owned plan catalog — staff pick a plan id here, never type a
  /// price. See server/store/schema.sql `plans` table.
  Future<List<AdminPlan>> listPlans();

  Future<AdminPaymentsPage> listPayments({
    String? status,
    String? userId,
    int limit = 50,
    int offset = 0,
  });

  /// Records a cash/bank-transfer payment. This alone does not grant access
  /// — [approvePayment] does that.
  Future<AdminPaymentRecord> recordPayment({
    required String userId,
    required String planId,
    required String method,
    required int amountTzs,
    String? reference,
    String? note,
  });

  /// Idempotent on the server: approving an already-approved record returns
  /// the existing entitlement rather than minting a second one.
  Future<AdminPaymentRecord> approvePayment(String paymentRecordId, {String? reason});

  Future<AdminPaymentRecord> reversePayment(String paymentRecordId, {String? reason});

  Future<List<AdminAuditEvent>> paymentAuditEvents(String paymentRecordId);
}

class AdminPaymentsPage {
  const AdminPaymentsPage({required this.total, required this.records});

  final int total;
  final List<AdminPaymentRecord> records;
}

class AdminException implements Exception {
  const AdminException(this.message);

  final String message;

  @override
  String toString() => 'AdminException: $message';
}
