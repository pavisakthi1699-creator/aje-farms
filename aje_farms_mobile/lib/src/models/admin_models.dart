import 'community_post.dart';
import 'course.dart';
import 'app_document.dart';

class AdminContentCourseRecord {
  const AdminContentCourseRecord({
    required this.id,
    required this.status,
    required this.course,
    required this.updatedAt,
  });

  final String id;
  final String status;
  final Course course;
  final DateTime updatedAt;
}

class AdminContentDocumentRecord {
  const AdminContentDocumentRecord({
    required this.id,
    required this.status,
    required this.document,
    required this.updatedAt,
  });

  final String id;
  final String status;
  final AppDocument document;
  final DateTime updatedAt;
}

class AdminSourceSegment {
  const AdminSourceSegment({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.sectionTitle,
    required this.locationLabel,
    required this.contentPreview,
  });

  final String id;
  final String documentId;
  final String documentTitle;
  final String? sectionTitle;
  final String locationLabel;
  final String contentPreview;
}

class AdminLessonSourceReviewResult {
  const AdminLessonSourceReviewResult({
    required this.courseUpdatedAt,
    required this.contentReady,
  });

  final DateTime courseUpdatedAt;
  final bool contentReady;
}

class AdminModerationReportStatus {
  const AdminModerationReportStatus({
    required this.postId,
    required this.reportedAt,
    required this.status,
    this.count = 0,
    this.reasons = const [],
  });

  final String postId;
  final DateTime reportedAt;
  final String status;
  final int count;
  final List<String> reasons;
}

class AdminModerationReport {
  const AdminModerationReport({
    required this.post,
    required this.report,
  });

  final CommunityPost post;
  final AdminModerationReportStatus report;
}

class AdminAiReport {
  const AdminAiReport({
    required this.id,
    required this.reason,
    required this.reportedAt,
    required this.prompt,
    required this.answer,
    this.details,
  });

  final String id;
  final String reason;
  final String? details;
  final DateTime reportedAt;
  final String prompt;
  final String answer;
}

class AdminAccountDeletionRequest {
  const AdminAccountDeletionRequest({
    required this.id,
    required this.email,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String email;
  final String status;
  final DateTime requestedAt;
}

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.email,
    required this.accountStatus,
    required this.displayName,
    required this.preferredLocation,
    required this.role,
    required this.subscriptionPlan,
    required this.subscriptionStartedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.learningProgressCount,
    required this.paymentTransactionsCount,
    required this.notificationCount,
    required this.communityPostsCount,
  });

  final String id;
  final String? email;

  /// 'pending_activation' | 'active' | 'suspended'.
  final String accountStatus;
  final String? displayName;
  final String? preferredLocation;
  final String role;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int learningProgressCount;
  final int paymentTransactionsCount;
  final int notificationCount;
  final int communityPostsCount;
}

class AdminPlan {
  const AdminPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceTzs,
    required this.durationDays,
    required this.recommended,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String price;
  final int priceTzs;
  final int durationDays;
  final bool recommended;
}

/// 'pending' | 'approved' | 'reversed'. See server/store/schema.sql.
class AdminPaymentRecord {
  const AdminPaymentRecord({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.method,
    required this.amountTzs,
    required this.currency,
    required this.reference,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? userEmail;
  final String planId;
  final String method;
  final int amountTzs;
  final String currency;
  final String? reference;
  final String? note;
  final String status;
  final DateTime createdAt;
}

class AdminAuditEvent {
  const AdminAuditEvent({
    required this.id,
    required this.actorUserId,
    required this.action,
    required this.previousStatus,
    required this.newStatus,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String? actorUserId;
  final String action;
  final String? previousStatus;
  final String? newStatus;
  final String? reason;
  final DateTime createdAt;
}

class AdminUsersPage {
  const AdminUsersPage({
    required this.total,
    required this.users,
  });

  final int total;
  final List<AdminUserSummary> users;
}
