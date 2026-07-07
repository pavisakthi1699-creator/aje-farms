abstract interface class LearningProgressService {
  Future<Set<String>> completedLessons(String phoneNumber);

  Future<void> markLessonCompleted({
    required String phoneNumber,
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
