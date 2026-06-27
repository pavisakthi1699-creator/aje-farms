import '../models/course.dart';
import '../models/problem_category.dart';

abstract interface class LearningRepository {
  List<Course> get courses;
  List<ProblemCategory> get problemCategories;

  Course get featuredCourse;
  Course get suggestedCourse;
}
