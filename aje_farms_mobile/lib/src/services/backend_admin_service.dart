import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/admin_models.dart';
import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/course.dart';
import 'admin_service.dart';
import 'backend_session_storage.dart';

class BackendAdminService implements AdminService {
  BackendAdminService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.videoUploadTimeout = const Duration(minutes: 10),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  /// Videos are large and admins are often on mobile data, so the upload gets
  /// far longer than an ordinary API call.
  final Duration videoUploadTimeout;

  @override
  Future<List<AdminContentCourseRecord>> listContentCourses() async {
    final payload = await _get('/api/admin/content/courses');
    final rows = (payload['courses'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    return rows.map(_contentCourseFromJson).toList();
  }

  @override
  Future<AdminContentCourseRecord> upsertContentCourse({
    required Course course,
    required String status,
    DateTime? baseUpdatedAt,
    bool createOnly = false,
  }) async {
    final payload = await _put(
      '/api/admin/content/courses/${Uri.encodeComponent(course.id)}',
      {
        'status': status,
        'course': _courseToJson(course),
        if (createOnly) 'createOnly': true,
        if (baseUpdatedAt != null) ...{
          'curriculumSchemaVersion': 2,
          'baseUpdatedAt': baseUpdatedAt.toUtc().toIso8601String(),
        },
      },
    );
    final row = payload['course'];
    if (row is! Map<String, dynamic>) {
      throw const AdminException('Invalid course response from admin service.');
    }
    return _contentCourseFromJson(row);
  }

  @override
  Future<List<AdminSourceSegment>> searchSourceSegments({
    String search = '',
  }) async {
    try {
      final uri =
          _baseUrl.resolve('/api/admin/content/source-segments').replace(
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'limit': '50',
        },
      );
      final payload = await _request(uri, method: _HttpMethod.get);
      final rows = (payload['segments'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      return rows.map(_sourceSegmentFromJson).toList();
    } on AdminException {
      rethrow;
    } catch (_) {
      throw const AdminException(
        'Admin service returned invalid source information.',
      );
    }
  }

  @override
  Future<AdminLessonSourceReviewResult> approveLessonSource({
    required String lessonId,
    required String sourceSegmentId,
    required String evidenceNote,
    required String groundingFact,
  }) async {
    final payload = await _post(
      '/api/admin/content/lessons/${Uri.encodeComponent(lessonId)}/source-review',
      {
        'sourceSegmentId': sourceSegmentId,
        'evidenceNote': evidenceNote,
        'groundingFact': groundingFact,
      },
    );
    final updatedAt = payload['courseUpdatedAt'];
    final parsedUpdatedAt =
        updatedAt is String ? DateTime.tryParse(updatedAt) : null;
    if (parsedUpdatedAt == null) {
      throw const AdminException(
        'Invalid source review response from admin service.',
      );
    }
    return AdminLessonSourceReviewResult(
      courseUpdatedAt: parsedUpdatedAt,
      contentReady: payload['contentReady'] == true,
    );
  }

  @override
  Future<String> uploadLessonVideo({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final payload = await _post(
      '/api/admin/content/lesson-videos/upload-url',
      {'contentType': contentType},
    );
    final uploadUrl = payload['uploadUrl'];
    final videoPath = payload['videoPath'];
    if (uploadUrl is! String || videoPath is! String) {
      throw const AdminException(
        'Admin service returned an invalid video upload target.',
      );
    }

    // The signed URL carries its own token, so this request deliberately
    // carries no session header — and it must not, since it goes to storage
    // rather than to our API.
    final http.Response response;
    try {
      response = await _client
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(videoUploadTimeout);
    } on TimeoutException {
      throw const AdminException(
        'Kupakia video kumechukua muda mrefu. Jaribu tena kwa mtandao bora.',
      );
    } on http.ClientException {
      throw const AdminException(
        'Imeshindikana kupakia video. Angalia mtandao wako.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AdminException(
        'Imeshindikana kupakia video. Jaribu tena.',
      );
    }
    return videoPath;
  }

  @override
  Future<List<AdminContentDocumentRecord>> listContentDocuments() async {
    final payload = await _get('/api/admin/content/documents');
    final rows = (payload['documents'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    return rows.map(_contentDocumentFromJson).toList();
  }

  @override
  Future<AdminContentDocumentRecord> upsertContentDocument({
    required AppDocument document,
    required String status,
  }) async {
    final payload = await _put(
      '/api/admin/content/documents/${Uri.encodeComponent(document.id)}',
      {'status': status, 'document': _documentToJson(document)},
    );
    final row = payload['document'];
    if (row is! Map<String, dynamic>) {
      throw const AdminException(
          'Invalid document response from admin service.');
    }
    return _contentDocumentFromJson(row);
  }

  @override
  Future<List<AdminModerationReport>> listModerationReports() async {
    final payload = await _get('/api/admin/moderation/reports');
    final rows = (payload['reports'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    return rows.map(_moderationReportFromJson).toList();
  }

  @override
  Future<CommunityPost> resolveModerationReport({
    required String postId,
    required String action,
  }) async {
    final payload = await _post(
      '/api/admin/moderation/posts/${Uri.encodeComponent(postId)}/resolve',
      {'action': action},
    );
    final row = payload['post'];
    if (row is! Map<String, dynamic>) {
      throw const AdminException(
          'Invalid moderation response from admin service.');
    }
    return _communityPostFromJson(row);
  }

  @override
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      'limit': '$limit',
      'offset': '$offset',
    };
    final uri =
        _baseUrl.resolve('/api/admin/users').replace(queryParameters: query);
    final payload = await _request(uri, method: _HttpMethod.get);
    final rows = (payload['users'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    return AdminUsersPage(
      total: (payload['total'] as num?)?.toInt() ?? 0,
      users: rows.map(_adminUserFromJson).toList(),
    );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    return _request(_baseUrl.resolve(path), method: _HttpMethod.get);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _request(
      _baseUrl.resolve(path),
      method: _HttpMethod.post,
      body: body,
    );
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _request(
      _baseUrl.resolve(path),
      method: _HttpMethod.put,
      body: body,
    );
  }

  Future<Map<String, dynamic>> _request(
    Uri uri, {
    required _HttpMethod method,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _headers();
      final response = switch (method) {
        _HttpMethod.get =>
          await _client.get(uri, headers: headers).timeout(timeout),
        _HttpMethod.post => await _client
            .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(timeout),
        _HttpMethod.put => await _client
            .put(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(timeout),
      };
      final payload =
          response.body.isEmpty ? const {} : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AdminException(
          payload is Map<String, dynamic> && payload['error'] is String
              ? payload['error'] as String
              : 'Admin request failed.',
        );
      }
      if (payload is! Map<String, dynamic>) {
        throw const AdminException(
          'Admin service returned an invalid response.',
        );
      }
      return payload;
    } on AdminException {
      rethrow;
    } on TimeoutException {
      throw const AdminException(
        'Admin service took too long to respond. Try again.',
      );
    } on http.ClientException {
      throw const AdminException(
        'Admin service could not be reached. Check your connection.',
      );
    } on FormatException {
      throw const AdminException(
        'Admin service returned an invalid response.',
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await BackendSessionStorage.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}

enum _HttpMethod { get, post, put }

AdminContentCourseRecord _contentCourseFromJson(Map<String, dynamic> json) {
  return AdminContentCourseRecord(
    id: json['id'] as String,
    status: json['status'] as String,
    course: _courseFromJson(json['course'] as Map<String, dynamic>),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

AdminContentDocumentRecord _contentDocumentFromJson(Map<String, dynamic> json) {
  return AdminContentDocumentRecord(
    id: json['id'] as String,
    status: json['status'] as String,
    document: _documentFromJson(json['document'] as Map<String, dynamic>),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

AdminSourceSegment _sourceSegmentFromJson(Map<String, dynamic> json) {
  return AdminSourceSegment(
    id: json['id'] as String,
    documentId: json['documentId'] as String,
    documentTitle: json['documentTitle'] as String,
    sectionTitle: json['sectionTitle'] as String?,
    locationLabel: json['locationLabel'] as String? ?? '',
    contentPreview: json['contentPreview'] as String? ?? '',
  );
}

AdminModerationReport _moderationReportFromJson(Map<String, dynamic> json) {
  final reportJson = json['report'] as Map<String, dynamic>;
  return AdminModerationReport(
    post: _communityPostFromJson(json['post'] as Map<String, dynamic>),
    report: AdminModerationReportStatus(
      postId: reportJson['postId'] as String,
      reportedAt: DateTime.parse(reportJson['reportedAt'] as String),
      status: reportJson['status'] as String,
    ),
  );
}

AdminUserSummary _adminUserFromJson(Map<String, dynamic> json) {
  return AdminUserSummary(
    id: json['id'] as String,
    phoneNumber: json['phoneNumber'] as String,
    displayName: json['displayName'] as String?,
    preferredLocation: json['preferredLocation'] as String?,
    role: json['role'] as String? ?? 'learner',
    subscriptionPlan: json['subscriptionPlan'] as String?,
    subscriptionStartedAt: (json['subscriptionStartedAt'] as String?) == null
        ? null
        : DateTime.parse(json['subscriptionStartedAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    learningProgressCount:
        (json['learningProgressCount'] as num?)?.toInt() ?? 0,
    paymentTransactionsCount:
        (json['paymentTransactionsCount'] as num?)?.toInt() ?? 0,
    notificationCount: (json['notificationCount'] as num?)?.toInt() ?? 0,
    communityPostsCount: (json['communityPostsCount'] as num?)?.toInt() ?? 0,
  );
}

Course _courseFromJson(Map<String, dynamic> json) {
  return Course(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    badge: json['badge'] as String,
    icon: _iconFromWire(json['icon'] as String),
    progress: (json['progress'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String,
    outcomes: (json['outcomes'] as List<dynamic>).cast<String>(),
    lessons: (json['lessons'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_lessonFromJson)
        .toList(),
  );
}

Lesson _lessonFromJson(Map<String, dynamic> json) {
  final readiness = json['readiness'] as Map<String, dynamic>?;
  return Lesson(
    id: json['id'] as String?,
    moduleId: json['moduleId'] as String?,
    moduleKey: json['moduleKey'] as String?,
    moduleTitle: json['moduleTitle'] as String?,
    title: json['title'] as String,
    type: _lessonTypeFromWire(json['type'] as String),
    meta: json['meta'] as String,
    description: json['description'] as String,
    durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    sourceTitle: json['sourceTitle'] as String?,
    resourceUrl: json['resourceUrl'] as String?,
    videoPath: json['videoPath'] as String?,
    isLearnerVisible: readiness?['visible'] as bool? ?? true,
    readinessReasons:
        (readiness?['reasons'] as List<dynamic>? ?? const <dynamic>[])
            .cast<String>(),
    isPremium: json['isPremium'] as bool? ?? false,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

AppDocument _documentFromJson(Map<String, dynamic> json) {
  return AppDocument(
    id: json['id'] as String,
    title: json['title'] as String,
    courseId: json['courseId'] as String,
    courseTitle: json['courseTitle'] as String,
    description: json['description'] as String,
    type: json['type'] as String? ?? 'pdf',
    sizeLabel: json['sizeLabel'] as String? ?? '',
    url: json['url'] as String?,
    isPremium: json['isPremium'] as bool? ?? false,
  );
}

CommunityPost _communityPostFromJson(Map<String, dynamic> json) {
  return CommunityPost(
    id: json['id'] as String,
    author: json['author'] as String,
    location: json['location'] as String,
    time: json['time'] as String,
    content: json['content'] as String,
    likes: json['likes'] as int,
    comments: json['comments'] as int,
    tags: (json['tags'] as List<dynamic>).cast<String>(),
    replies: (json['replies'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_communityReplyFromJson)
        .toList(),
    relatedTopic: json['relatedTopic'] as String?,
    // Without this a reported post rendered the grey placeholder instead of
    // the photo the moderator is being asked to judge.
    imageUrl: json['imageUrl'] as String?,
    hasImage: json['hasImage'] as bool? ?? false,
    isExpert: json['isExpert'] as bool? ?? false,
    isUrgent: json['isUrgent'] as bool? ?? false,
  );
}

CommunityReply _communityReplyFromJson(Map<String, dynamic> json) {
  return CommunityReply(
    author: json['author'] as String,
    body: json['body'] as String,
    time: json['time'] as String,
    isExpert: json['isExpert'] as bool? ?? false,
  );
}

Map<String, dynamic> _courseToJson(Course course) {
  return {
    'id': course.id,
    'title': course.title,
    'description': course.description,
    'badge': course.badge,
    'icon': _iconToWire(course.icon),
    'progress': course.progress,
    'imageUrl': course.imageUrl,
    'outcomes': course.outcomes,
    'lessons': course.lessons.map(_lessonToJson).toList(),
  };
}

Map<String, dynamic> _lessonToJson(Lesson lesson) {
  return {
    if (lesson.id != null) 'id': lesson.id,
    if (lesson.moduleId != null) 'moduleId': lesson.moduleId,
    if (lesson.moduleKey != null) 'moduleKey': lesson.moduleKey,
    if (lesson.moduleTitle != null) 'moduleTitle': lesson.moduleTitle,
    'title': lesson.title,
    'type': lesson.type.name,
    'meta': lesson.meta,
    'description': lesson.description,
    if (lesson.durationMinutes != null)
      'durationMinutes': lesson.durationMinutes,
    if (lesson.sourceTitle != null) 'sourceTitle': lesson.sourceTitle,
    if (lesson.resourceUrl != null) 'resourceUrl': lesson.resourceUrl,
    if (lesson.videoPath != null) 'videoPath': lesson.videoPath,
    'isPremium': lesson.isPremium,
    'isCompleted': lesson.isCompleted,
  };
}

Map<String, dynamic> _documentToJson(AppDocument document) {
  return {
    'id': document.id,
    'title': document.title,
    'courseId': document.courseId,
    'courseTitle': document.courseTitle,
    'description': document.description,
    'type': document.type,
    'sizeLabel': document.sizeLabel,
    if (document.url != null) 'url': document.url,
    'isPremium': document.isPremium,
  };
}

LessonType _lessonTypeFromWire(String value) {
  return LessonType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => LessonType.reading,
  );
}

IconData _iconFromWire(String value) {
  return switch (value) {
    'bug_report' => Icons.bug_report,
    'calendar_month' => Icons.calendar_month,
    'eco' => Icons.eco,
    'egg_alt' => Icons.egg_alt,
    'grass' => Icons.grass,
    'handshake' => Icons.handshake,
    'local_florist' => Icons.local_florist,
    'menu_book' => Icons.menu_book,
    'play_circle' => Icons.play_circle_outline,
    'spa' => Icons.spa,
    'star' => Icons.star,
    'trending_up' => Icons.trending_up,
    'water_drop' => Icons.water_drop,
    _ => Icons.agriculture,
  };
}

String _iconToWire(IconData icon) {
  if (icon == Icons.bug_report) return 'bug_report';
  if (icon == Icons.calendar_month) return 'calendar_month';
  if (icon == Icons.eco) return 'eco';
  if (icon == Icons.egg_alt) return 'egg_alt';
  if (icon == Icons.grass) return 'grass';
  if (icon == Icons.handshake) return 'handshake';
  if (icon == Icons.local_florist) return 'local_florist';
  if (icon == Icons.menu_book) return 'menu_book';
  if (icon == Icons.play_circle_outline) return 'play_circle';
  if (icon == Icons.spa) return 'spa';
  if (icon == Icons.star) return 'star';
  if (icon == Icons.trending_up) return 'trending_up';
  if (icon == Icons.water_drop) return 'water_drop';
  return 'agriculture';
}
