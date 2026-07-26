import '../models/admin_models.dart';
import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/course.dart';
import 'admin_service.dart';

class LocalAdminService implements AdminService {
  const LocalAdminService();

  @override
  Future<List<AdminContentCourseRecord>> listContentCourses() async {
    return const [];
  }

  @override
  Future<AdminContentCourseRecord> upsertContentCourse({
    required Course course,
    required String status,
    DateTime? baseUpdatedAt,
  }) async {
    throw const AdminException(
      'Admin content management requires a connected backend.',
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
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async {
    return const AdminUsersPage(total: 0, users: []);
  }
}
