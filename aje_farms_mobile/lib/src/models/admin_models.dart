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

class AdminModerationReportStatus {
  const AdminModerationReportStatus({
    required this.postId,
    required this.reportedAt,
    required this.status,
  });

  final String postId;
  final DateTime reportedAt;
  final String status;
}

class AdminModerationReport {
  const AdminModerationReport({
    required this.post,
    required this.report,
  });

  final CommunityPost post;
  final AdminModerationReportStatus report;
}

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.phoneNumber,
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
  final String phoneNumber;
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

class AdminUsersPage {
  const AdminUsersPage({
    required this.total,
    required this.users,
  });

  final int total;
  final List<AdminUserSummary> users;
}
