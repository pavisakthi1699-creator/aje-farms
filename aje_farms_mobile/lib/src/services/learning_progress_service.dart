abstract interface class LearningProgressService {
  Future<Set<String>> completedLessons();

  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
  });
}

class LearningProgressException implements Exception {
  const LearningProgressException(this.message);

  final String message;

  @override
  String toString() => 'LearningProgressException: $message';
}
