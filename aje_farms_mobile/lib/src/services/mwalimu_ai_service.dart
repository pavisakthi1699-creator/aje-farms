abstract interface class MwalimuAiService {
  Future<MwalimuAiAnswer> answer(String prompt);
}

class MwalimuAiAnswer {
  const MwalimuAiAnswer({
    required this.text,
    this.sources = const [],
  });

  final String text;
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
  const MwalimuAiException(this.message);

  final String message;

  @override
  String toString() => 'MwalimuAiException: $message';
}
