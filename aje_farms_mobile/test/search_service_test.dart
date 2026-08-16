import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aje_farms_mobile/src/models/search_result.dart';
import 'package:aje_farms_mobile/src/models/community_post.dart';
import 'package:aje_farms_mobile/src/models/app_document.dart';
import 'package:aje_farms_mobile/src/models/course.dart';
import 'package:aje_farms_mobile/src/models/problem_category.dart';
import 'package:aje_farms_mobile/src/repositories/cached_app_repository.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';
import 'package:aje_farms_mobile/src/repositories/community_repository.dart';
import 'package:aje_farms_mobile/src/repositories/learning_repository.dart';
import 'package:aje_farms_mobile/src/services/local_catalog_service.dart';
import 'package:aje_farms_mobile/src/services/local_search_service.dart';
import 'package:aje_farms_mobile/src/services/search_service.dart';

void main() {
  const repository = DemoAppRepository();
  final service = LocalSearchService(
    learningRepository: repository,
    communityRepository: repository,
  );

  test('local search finds and ranks learning content', () async {
    final response = await service.search(
      const SearchRequest(query: 'nyanya', scope: SearchScope.learning),
    );

    expect(response.query, 'nyanya');
    expect(response.isOffline, isTrue);
    expect(response.results, isNotEmpty);
    expect(response.results.first.kind, SearchResultKind.course);
    expect(response.results.first.id, 'nyanya');
  });

  test('local search tolerates a one-word typo and respects scope', () async {
    final typo = await service.search(
      const SearchRequest(query: 'nyaynya', scope: SearchScope.learning),
    );
    expect(typo.results.first.id, 'nyanya');

    final community = await service.search(
      const SearchRequest(query: 'jamii', scope: SearchScope.community),
    );
    expect(
      community.results.every(
        (result) => result.kind == SearchResultKind.community,
      ),
      isTrue,
    );
  });

  test('local search validates query and result limits', () async {
    await expectLater(
      service.search(const SearchRequest(query: 'x')),
      throwsA(isA<SearchException>()),
    );
    await expectLater(
      service.search(const SearchRequest(query: 'mpunga', limit: 51)),
      throwsA(isA<SearchException>()),
    );
  });

  test('normalization matches the shared cross-runtime fixture', () {
    final fixture = jsonDecode(
      File('../fixtures/search_normalization_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final entry in fixture['cases'] as List<dynamic>) {
      final searchCase = entry as Map<String, dynamic>;
      expect(
        normalizeSearchText(searchCase['input'] as String),
        searchCase['expected'],
        reason: 'input=${searchCase['input']}',
      );
    }
  });

  test('query validation counts normalized Unicode code points', () async {
    final fixture = jsonDecode(
      File('../fixtures/search_normalization_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final entry in fixture['boundaries'] as List<dynamic>) {
      final boundary = entry as Map<String, dynamic>;
      final request = SearchRequest(
        query: 'a' * (boundary['codePoints'] as int),
      );
      if (boundary['valid'] as bool) {
        await expectLater(service.search(request), completes);
      } else {
        await expectLater(
            service.search(request), throwsA(isA<SearchException>()));
      }
    }
  });

  test('reuses one base index until searchable content generation changes',
      () async {
    final cachedRepository = CachedAppRepository(
      learningSeed: repository,
      communitySeed: repository,
      subscriptionSeed: repository,
    );
    final indexedService = LocalSearchService(
      learningRepository: cachedRepository,
      communityRepository: cachedRepository,
      cachedRepository: cachedRepository,
    );
    addTearDown(indexedService.dispose);

    await indexedService.search(const SearchRequest(query: 'nyanya'));
    final firstBuildCount = indexedService.debugIndexBuildCount;
    await indexedService.search(const SearchRequest(query: 'mpunga'));

    expect(indexedService.debugIndexBuildCount, firstBuildCount);
    expect(indexedService.debugIndexedRecordCount, greaterThan(0));

    cachedRepository.clearProtectedContent();

    expect(indexedService.debugIndexedRecordCount, 0);
    await indexedService.search(const SearchRequest(query: 'nyanya'));
    expect(indexedService.debugIndexBuildCount, firstBuildCount + 1);

    await cachedRepository.refresh(const LocalCatalogService());

    expect(indexedService.debugIndexedRecordCount, 0);
    await indexedService.search(const SearchRequest(query: 'nyanya'));
    expect(indexedService.debugIndexBuildCount, firstBuildCount + 2);
  });

  test('indexes only the session-local community overlay without duplicates',
      () async {
    final indexedService = LocalSearchService(
      learningRepository: repository,
      communityRepository: repository,
    );
    addTearDown(indexedService.dispose);
    await indexedService.search(const SearchRequest(query: 'jamii'));
    final baseBuildCount = indexedService.debugIndexBuildCount;

    final localResult = await indexedService.search(
      const SearchRequest(
        query: 'mavuno mapya',
        scope: SearchScope.community,
        localCommunityPosts: [
          CommunityPost(
            id: 'local-post',
            author: 'Mkulima',
            location: 'Arusha',
            time: 'Sasa',
            content: 'Mavuno mapya ya nyanya',
            likes: 0,
            comments: 0,
            tags: ['Nyanya'],
            replies: [],
          ),
        ],
      ),
    );
    final duplicateResult = await indexedService.search(
      const SearchRequest(
        query: 'zebramatch',
        scope: SearchScope.community,
        localCommunityPosts: [
          CommunityPost(
            id: 'seed-community-guidelines',
            author: 'Mkulima',
            location: 'Arusha',
            time: 'Sasa',
            content: 'zebramatch should not replace the cached post',
            likes: 0,
            comments: 0,
            tags: [],
            replies: [],
          ),
        ],
      ),
    );

    expect(localResult.results.single.id, 'local-post');
    expect(duplicateResult.results, isEmpty);
    expect(indexedService.debugIndexBuildCount, baseBuildCount);
  });

  test('bounded selection preserves deterministic ties at every result limit',
      () async {
    final largeRepository = _DocumentSearchRepository(60);
    final indexedService = LocalSearchService(
      learningRepository: largeRepository,
      communityRepository: largeRepository,
    );
    addTearDown(indexedService.dispose);

    for (final limit in [1, 20, 50]) {
      final first = await indexedService.search(
        SearchRequest(
          query: 'mwongozo nyanya',
          scope: SearchScope.documents,
          limit: limit,
        ),
      );
      final repeated = await indexedService.search(
        SearchRequest(
          query: 'mwongozo nyanya',
          scope: SearchScope.documents,
          limit: limit,
        ),
      );

      expect(first.truncated, isTrue);
      expect(first.results, hasLength(limit));
      expect(
        first.results.map((result) => result.id),
        [
          for (var index = 0; index < limit; index += 1)
            'doc-${index.toString().padLeft(3, '0')}',
        ],
      );
      expect(
        repeated.results.map((result) => result.id),
        first.results.map((result) => result.id),
      );
    }
  });

  test('saved-document boost is applied before top-K admission', () async {
    final largeRepository = _DocumentSearchRepository(60);
    final indexedService = LocalSearchService(
      learningRepository: largeRepository,
      communityRepository: largeRepository,
    );
    addTearDown(indexedService.dispose);

    final response = await indexedService.search(
      const SearchRequest(
        query: 'mwongozo nyanya',
        scope: SearchScope.documents,
        limit: 1,
        savedDocumentIds: {'doc-059'},
      ),
    );

    expect(response.results.single.id, 'doc-059');
    expect(response.truncated, isTrue);
  });

  test('limits lesson results to three per course before truncation', () async {
    final lessonRepository = _LessonSearchRepository();
    final indexedService = LocalSearchService(
      learningRepository: lessonRepository,
      communityRepository: lessonRepository,
    );
    addTearDown(indexedService.dispose);

    final response = await indexedService.search(
      const SearchRequest(
        query: 'nyanya afya',
        scope: SearchScope.learning,
        limit: 10,
      ),
    );

    expect(
      response.results.where((result) => result.parentId == 'course-a').length,
      3,
    );
    expect(
      response.results.any((result) => result.parentId == 'course-b'),
      isTrue,
    );
  });
}

class _LessonSearchRepository
    implements LearningRepository, CommunityRepository {
  @override
  List<Course> get courses => [
        Course(
          id: 'course-a',
          title: 'Kozi A',
          description: 'Mafunzo ya shamba',
          badge: 'Mafunzo',
          icon: Icons.agriculture,
          progress: 0,
          imageUrl: '',
          outcomes: const [],
          lessons: [
            for (var index = 0; index < 5; index += 1)
              Lesson(
                id: 'a-$index',
                title: 'Nyanya afya somo $index',
                type: LessonType.reading,
                meta: '',
                description: 'Nyanya afya',
              ),
          ],
        ),
        const Course(
          id: 'course-b',
          title: 'Kozi B',
          description: 'Mafunzo mengine',
          badge: 'Mafunzo',
          icon: Icons.agriculture,
          progress: 0,
          imageUrl: '',
          outcomes: [],
          lessons: [
            Lesson(
              id: 'b-0',
              title: 'Nyanya afya somo la ziada',
              type: LessonType.reading,
              meta: '',
              description: 'Nyanya afya',
            ),
          ],
        ),
      ];

  @override
  List<AppDocument> get documents => const [];

  @override
  List<ProblemCategory> get problemCategories => const [];

  @override
  List<CommunityPost> get posts => const [];

  @override
  List<String> get homeTopics => const [];

  @override
  List<String> get communityTopics => const [];

  @override
  Course? get featuredCourse => courses.first;

  @override
  Course? get suggestedCourse => courses.last;
}

class _DocumentSearchRepository
    implements LearningRepository, CommunityRepository {
  _DocumentSearchRepository(int documentCount)
      : documents = [
          for (var index = 0; index < documentCount; index += 1)
            AppDocument(
              id: 'doc-${index.toString().padLeft(3, '0')}',
              title: 'Mwongozo wa nyanya',
              courseId: 'nyanya',
              courseTitle: 'Kilimo cha Nyanya',
              description: 'Mwongozo wa nyanya kwa mkulima',
              type: 'PDF',
              sizeLabel: '1 MB',
            ),
        ];

  @override
  final List<AppDocument> documents;

  @override
  List<CommunityPost> get posts => const [];

  @override
  List<Course> get courses => const [];

  @override
  List<ProblemCategory> get problemCategories => const [];

  @override
  List<String> get homeTopics => const [];

  @override
  List<String> get communityTopics => const [];

  @override
  Course? get featuredCourse => null;

  @override
  Course? get suggestedCourse => null;
}
