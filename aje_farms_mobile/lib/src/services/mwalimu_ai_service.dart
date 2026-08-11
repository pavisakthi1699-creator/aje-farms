abstract interface class MwalimuAiService {
  Future<MwalimuAiAnswer> answer(String prompt);
  Future<void> reportAnswer(
    String messageId, {
    required String reason,
    String? details,
  });
}

class MwalimuAiAnswer {
  const MwalimuAiAnswer({
    required this.text,
    this.messageId,
    this.sources = const [],
  });

  final String text;
  final String? messageId;
  final List<MwalimuAiSource> sources;
}

class MwalimuAiSource {
  const MwalimuAiSource({
    required this.id,
    required this.courseId,
    required this.lessonId,
    required this.courseTitle,
    required this.title,
    required this.type,
    required this.excerpt,
  });

  final String id;
  final String courseId;
  final String lessonId;
  final String courseTitle;
  final String title;
  final String type;
  final String excerpt;
}

class MwalimuAiException implements Exception {
  const MwalimuAiException(this.message, {this.statusCode});

  final String message;

  /// The backend status, when the failure came from a response rather than
  /// from the transport. Null for timeouts and socket errors.
  final int? statusCode;

  /// True when the learner is signed in but an admin has not yet verified the
  /// account. Callers route this to the paywall instead of reporting a
  /// network fault — the request itself succeeded.
  bool get requiresVerifiedAccount => statusCode == 403;

  @override
  String toString() => 'MwalimuAiException: $message';
}
