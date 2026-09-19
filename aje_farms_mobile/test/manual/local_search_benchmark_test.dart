import 'dart:convert';

import 'package:aje_farms_mobile/src/models/app_document.dart';
import 'package:aje_farms_mobile/src/models/community_post.dart';
import 'package:aje_farms_mobile/src/models/course.dart';
import 'package:aje_farms_mobile/src/models/problem_category.dart';
import 'package:aje_farms_mobile/src/models/search_result.dart';
import 'package:aje_farms_mobile/src/repositories/community_repository.dart';
import 'package:aje_farms_mobile/src/repositories/learning_repository.dart';
import 'package:aje_farms_mobile/src/services/local_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('AJE_RUN_SEARCH_BENCHMARK');

void main() {
  test('manual large-cache offline search benchmark', () async {
    if (!_enabled) return;

    final repository = _BenchmarkRepository();
    final service = LocalSearchService(
      learningRepository: repository,
      communityRepository: repository,
    );
    const queries = [
      'nyanya ugonjwa',
      'mpunga maji',
      'mbolea udongo',
      'wadudu mimea',
      'mwongozo shamba',
      'mavuno soko',
      'kuku chanjo',
      'umwagiliaji',
      'kilimo salama',
      'jamii wakulima',
    ];

    final coldWatch = Stopwatch()..start();
    await service.search(const SearchRequest(query: 'nyanya ugonjwa'));
    coldWatch.stop();

    for (var index = 0; index < 30; index += 1) {
      await service
          .search(SearchRequest(query: queries[index % queries.length]));
    }

    final warmMicros = <int>[];
    for (var index = 0; index < 300; index += 1) {
      final watch = Stopwatch()..start();
      await service
          .search(SearchRequest(query: queries[index % queries.length]));
      watch.stop();
      warmMicros.add(watch.elapsedMicroseconds);
    }
    warmMicros.sort();

    // A machine-readable line makes before/after runs easy to compare without
    // turning variable CI hardware into a flaky pass/fail gate.
    // ignore: avoid_print
    print(
      'SEARCH_BENCHMARK ${jsonEncode({
            'corpus': {
              'courses': repository.courses.length,
              'lessons':
                  repository.courses.expand((course) => course.lessons).length,
              'documents': repository.documents.length,
              'problems': repository.problemCategories.length,
              'communityPosts': repository.posts.length,
            },
            'coldBuildAndQueryMs': coldWatch.elapsedMicroseconds / 1000,
            'warmQueryP50Ms': _percentile(warmMicros, 0.50) / 1000,
            'warmQueryP95Ms': _percentile(warmMicros, 0.95) / 1000,
          })}',
    );
  });
}

int _percentile(List<int> sortedValues, double percentile) {
  final index = ((sortedValues.length - 1) * percentile).round();
  return sortedValues[index];
}

class _BenchmarkRepository implements LearningRepository, CommunityRepository {
  _BenchmarkRepository()
      : courses = [
          for (var courseIndex = 0; courseIndex < 500; courseIndex += 1)
            Course(
              id: 'course-$courseIndex',
              title: 'Kilimo salama cha nyanya $courseIndex',
              description: 'Udongo mbolea maji wadudu magonjwa mavuno na soko',
              badge: 'Mafunzo',
              icon: Icons.agriculture,
              progress: 0,
              imageUrl: '',
              outcomes: const ['Mavuno bora', 'Udongo salama'],
              lessons: [
                for (var lessonIndex = 0; lessonIndex < 20; lessonIndex += 1)
                  Lesson(
                    id: 'lesson-$courseIndex-$lessonIndex',
                    title: 'Nyanya ugonjwa somo $lessonIndex',
                    type: LessonType.reading,
                    meta: 'Dakika 5',
                    description: 'Dalili za mimea maji mbolea wadudu na mavuno',
                    moduleTitle: 'Magonjwa ya mimea',
                    sourceTitle: 'Mwongozo wa shamba',
                  ),
              ],
            ),
        ],
        documents = [
          for (var index = 0; index < 2000; index += 1)
            AppDocument(
              id: 'document-$index',
              title: 'Mwongozo wa shamba $index',
              courseId: 'course-${index % 500}',
              courseTitle: 'Kilimo cha nyanya',
              description: 'Mbolea udongo maji mavuno soko na wadudu',
              type: 'PDF',
              sizeLabel: '1 MB',
            ),
        ],
        problemCategories = [
          for (var index = 0; index < 100; index += 1)
            ProblemCategory(
              title: 'Wadudu na mimea $index',
              topic: 'Wadudu $index',
              icon: Icons.bug_report,
              color: Colors.green,
              summary: 'Magonjwa mbolea maji na udongo',
              examples: const ['Nyanya', 'Mpunga'],
            ),
        ],
        posts = [
          for (var index = 0; index < 10000; index += 1)
            CommunityPost(
              id: 'post-$index',
              author: 'Mkulima',
              location: 'Tanzania',
              time: 'Leo',
              content:
                  'Jamii ya wakulima nyanya mpunga maji mavuno soko $index',
              likes: 0,
              comments: 0,
              tags: const ['Jamii', 'Wakulima'],
              replies: const [],
              relatedTopic: 'Kilimo salama',
            ),
        ];

  @override
  final List<Course> courses;

  @override
  final List<AppDocument> documents;

  @override
  final List<ProblemCategory> problemCategories;

  @override
  final List<CommunityPost> posts;

  @override
  List<String> get homeTopics => const [];

  @override
  List<String> get communityTopics => const [];

  @override
  Course? get featuredCourse => courses.isEmpty ? null : courses.first;

  @override
  Course? get suggestedCourse => courses.isEmpty ? null : courses.last;
}
