import 'package:aje_farms_mobile/src/models/course.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = DemoAppRepository();

  test('seed courses do not claim unsupported media or prefilled progress', () {
    for (final course in repository.courses) {
      expect(course.progress, 0);
      expect(course.lessons, isNotEmpty);
      expect(course.lessons.every((lesson) => !lesson.isCompleted), isTrue);
      expect(
        course.lessons.every((lesson) => lesson.type == LessonType.reading),
        isTrue,
      );
      expect(
        course.lessons.every((lesson) => !lesson.meta.contains('MB')),
        isTrue,
      );
    }
  });

  test('seed community content is evergreen and not fabricated engagement', () {
    expect(repository.posts, hasLength(1));
    final post = repository.posts.single;
    expect(post.author, 'Timu ya Chuo Kikuu Cha Mtaani');
    expect(post.likes, 0);
    expect(post.comments, 0);
    expect(post.replies, isEmpty);
    expect(post.content.toLowerCase(), isNot(contains('bei')));
    expect(post.time.toLowerCase(), isNot(contains('leo')));
  });
}
