import 'package:aje_farms_mobile/src/app/app_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production starts empty instead of exposing demo content', () {
    final dependencies = AppDependencies.production(
      baseUrl: Uri.parse('https://api.ajefarms.test'),
    );

    expect(dependencies.learningRepository.courses, isEmpty);
    expect(dependencies.learningRepository.documents, isEmpty);
    expect(dependencies.learningRepository.problemCategories, isEmpty);
    expect(dependencies.learningRepository.homeTopics, isEmpty);
    expect(dependencies.communityRepository.posts, isEmpty);
    expect(dependencies.communityRepository.communityTopics, isEmpty);
    expect(dependencies.subscriptionRepository.plans, isEmpty);
  });
}
