import '../models/admin_models.dart';
import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/community_topics.dart';
import '../models/course.dart';
import '../models/home_topics.dart';
import 'admin_service.dart';

class LocalAdminService implements AdminService {
  const LocalAdminService();

  @override
  Future<List<String>> getHomeTopics() async => defaultHomeTopics;

  @override
  Future<List<String>> updateHomeTopics(List<String> topics) async {
    throw const AdminException(
      'Kubadilisha mada kunahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<List<String>> getCommunityTopics() async => defaultCommunityTopics;

  @override
  Future<List<String>> updateCommunityTopics(List<String> topics) async {
    throw const AdminException(
      'Kubadilisha mada za jamii kunahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<List<AdminContentCourseRecord>> listContentCourses() async {
    return const [];
  }

  @override
  Future<AdminContentCourseRecord> upsertContentCourse({
    required Course course,
    required String status,
    DateTime? baseUpdatedAt,
    bool createOnly = false,
  }) async {
    throw const AdminException(
      'Admin content management requires a connected backend.',
    );
  }

  @override
  Future<bool> deleteContentCourse(String courseId) async {
    throw const AdminException(
      'Course deletion requires a connected backend.',
    );
  }

  @override
  Future<List<AdminSourceSegment>> searchSourceSegments({
    String search = '',
  }) async {
    return const [];
  }

  @override
  Future<AdminLessonSourceReviewResult> approveLessonSource({
    required String lessonId,
    required String sourceSegmentId,
    required String evidenceNote,
    required String groundingFact,
  }) async {
    throw const AdminException(
      'Source review requires a connected backend.',
    );
  }

  @override
  Future<AdminLessonSourceReviewResult> registerUploadedVideoEvidence({
    required String lessonId,
    required String transcript,
    required String evidenceNote,
    required String groundingFact,
  }) async {
    throw const AdminException(
      'Ushahidi wa video unahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<String> uploadLessonVideo({
    required Stream<List<int>> stream,
    required int contentLength,
    required String contentType,
  }) async {
    throw const AdminException(
      'Upload ya video inahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<String> uploadContentMedia({
    required Stream<List<int>> stream,
    required int contentLength,
    required String contentType,
    required String kind,
  }) async {
    throw const AdminException(
        'Upload ya media inahitaji backend iliyounganishwa.');
  }

  @override
  Future<void> deleteUploadedMedia(
      {String? videoPath, String? publicUrl}) async {
    throw const AdminException(
      'Media cleanup requires a connected backend.',
    );
  }

  @override
  Future<List<AdminContentDocumentRecord>> listContentDocuments() async {
    return const [];
  }

  @override
  Future<AdminContentDocumentRecord> upsertContentDocument({
    required AppDocument document,
    required String status,
  }) async {
    throw const AdminException(
      'Admin document management requires a connected backend.',
    );
  }

  @override
  Future<List<AdminModerationReport>> listModerationReports() async {
    return const [];
  }

  @override
  Future<CommunityPost> resolveModerationReport({
    required String postId,
    required String action,
  }) async {
    throw const AdminException(
      'Moderation management requires a connected backend.',
    );
  }

  @override
  Future<List<AdminAiReport>> listAiReports() async => const [];

  @override
  Future<void> resolveAiReport(String reportId, {String? note}) async {
    throw const AdminException(
      'Usimamizi wa ripoti za AI unahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<List<AdminAccountDeletionRequest>>
      listAccountDeletionRequests() async => const [];

  @override
  Future<void> resolveAccountDeletionRequest({
    required String requestId,
    required String status,
    String? note,
  }) async {
    throw const AdminException(
      'Maombi ya kufuta akaunti yanahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<void> updateUserAccess({
    required String userId,
    required String action,
    String? reason,
  }) async {
    throw const AdminException(
      'Usimamizi wa ufikiaji unahitaji backend iliyounganishwa.',
    );
  }

  @override
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async {
    return const AdminUsersPage(total: 0, users: []);
  }

  @override
  Future<List<AdminPlan>> listPlans() async {
    return const [
      AdminPlan(
        id: 'wiki-1',
        title: 'Wiki 1',
        subtitle: 'Ufikiaji wa haraka',
        price: 'TZS 3,000',
        priceTzs: 3000,
        durationDays: 7,
        recommended: false,
      ),
      AdminPlan(
        id: 'mwezi-1',
        title: 'Mwezi 1',
        subtitle: 'Thamani bora zaidi',
        price: 'TZS 10,000',
        priceTzs: 10000,
        durationDays: 30,
        recommended: true,
      ),
    ];
  }

  @override
  Future<AdminPaymentsPage> listPayments({
    String? status,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    return const AdminPaymentsPage(total: 0, records: []);
  }

  @override
  Future<AdminPaymentRecord> recordPayment({
    required String userId,
    required String planId,
    required String method,
    required int amountTzs,
    String? reference,
    String? note,
  }) async {
    return AdminPaymentRecord(
      id: 'demo-payment',
      userId: userId,
      userEmail: null,
      planId: planId,
      method: method,
      amountTzs: amountTzs,
      currency: 'TZS',
      reference: reference,
      note: note,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AdminPaymentRecord> approvePayment(
    String paymentRecordId, {
    String? reason,
  }) async {
    return AdminPaymentRecord(
      id: paymentRecordId,
      userId: 'demo-user',
      userEmail: null,
      planId: 'wiki-1',
      method: 'cash',
      amountTzs: 3000,
      currency: 'TZS',
      reference: null,
      note: null,
      status: 'approved',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AdminPaymentRecord> reversePayment(
    String paymentRecordId, {
    String? reason,
  }) async {
    return AdminPaymentRecord(
      id: paymentRecordId,
      userId: 'demo-user',
      userEmail: null,
      planId: 'wiki-1',
      method: 'cash',
      amountTzs: 3000,
      currency: 'TZS',
      reference: null,
      note: null,
      status: 'reversed',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<AdminAuditEvent>> paymentAuditEvents(
    String paymentRecordId,
  ) async {
    return const [];
  }
}
