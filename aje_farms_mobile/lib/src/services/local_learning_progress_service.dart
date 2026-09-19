import 'learning_progress_service.dart';

class LocalLearningProgressService implements LearningProgressService {
  const LocalLearningProgressService();

  @override
  Future<Set<String>> completedLessons() async {
    return {};
  }

  @override
  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
  }) async {}
}
