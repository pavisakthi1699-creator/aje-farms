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
}

class AdminException implements Exception {
  const AdminException(this.message);

  final String message;

  @override
  String toString() => 'AdminException: $message';
}
