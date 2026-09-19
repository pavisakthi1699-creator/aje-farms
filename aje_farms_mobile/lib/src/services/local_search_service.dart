import 'package:flutter/foundation.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/search_result.dart';
import '../repositories/cached_app_repository.dart';
import '../repositories/community_repository.dart';
import '../repositories/learning_repository.dart';
import 'search_service.dart';

const _maxLessonsPerCourse = 3;

class LocalSearchService implements SearchService {
  LocalSearchService({
    required this.learningRepository,
    required this.communityRepository,
    this.cachedRepository,
  }) {
    cachedRepository?.addListener(_handleContentChanged);
  }

  final LearningRepository learningRepository;
  final CommunityRepository communityRepository;
  final CachedAppRepository? cachedRepository;

  List<_IndexedRecord>? _baseIndex;
  int? _indexedGeneration;
  int _indexBuildCount = 0;

  @visibleForTesting
  int get debugIndexBuildCount => _indexBuildCount;

  @visibleForTesting
  int get debugIndexedRecordCount => _baseIndex?.length ?? 0;

  void dispose() {
    cachedRepository?.removeListener(_handleContentChanged);
    _clearIndex();
  }

  void _handleContentChanged() {
    if (_indexedGeneration != cachedRepository?.contentGeneration) {
      _clearIndex();
    }
  }

  void _clearIndex() {
    _baseIndex = null;
    _indexedGeneration = null;
  }

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    final query = normalizeSearchText(request.query);
    if (query.runes.length < 2 || query.runes.length > 120) {
      throw const SearchException('Andika herufi 2 hadi 120 ili kutafuta.');
    }
    if (request.limit < 1 || request.limit > 50) {
      throw const SearchException('Idadi ya matokeo lazima iwe 1 hadi 50.');
    }

    final baseIndex = _ensureBaseIndex();
    final records = <_IndexedRecord>[
      ...baseIndex,
      ..._localCommunityOverlay(baseIndex, request.localCommunityPosts),
    ];
    final queryTrigrams = _trigrams(query);
    final topMatches = <_Match>[];
    final lessonMatchesByParent = <String, List<_Match>>{};
    var matchCount = 0;

    for (final record in records) {
      if (!_includedInScope(record.kind, request.scope)) continue;
      final relevance = _score(record, query, queryTrigrams);
      final savedBoost = relevance > 0 &&
              request.scope == SearchScope.documents &&
              record.kind == SearchResultKind.document &&
              request.savedDocumentIds.contains(record.id)
          ? 2000
          : 0;
      final score = relevance + savedBoost;
      if (score <= 0) continue;
      final match = _Match(record: record, score: score);
      if (record.kind == SearchResultKind.lesson) {
        final parentKey = record.result.parentId ?? record.id;
        _insertTopMatch(
          lessonMatchesByParent.putIfAbsent(parentKey, () => []),
          match,
          _maxLessonsPerCourse,
        );
        continue;
      }
      matchCount += 1;
      _insertTopMatch(topMatches, match, request.limit);
    }
    for (final lessonMatches in lessonMatchesByParent.values) {
      matchCount += lessonMatches.length;
      for (final match in lessonMatches) {
        _insertTopMatch(topMatches, match, request.limit);
      }
    }

    return SearchResponse(
      query: query,
      scope: request.scope,
      results: [for (final match in topMatches) match.record.result],
      truncated: matchCount > request.limit,
      isOffline: true,
    );
  }

  List<_IndexedRecord> _ensureBaseIndex() {
    final generation = cachedRepository?.contentGeneration ?? 0;
    final existing = _baseIndex;
    if (existing != null && _indexedGeneration == generation) return existing;

    final records = <_IndexedRecord>[];
    for (final course in learningRepository.courses) {
      records.add(
        _indexRecord(
          result: SearchResult(
            kind: SearchResultKind.course,
            id: course.id,
            title: course.title,
            snippet: course.description,
            metadata: 'Kozi',
          ),
          body: '${course.description} ${course.outcomes.join(' ')}',
          tags: [course.badge],
        ),
      );
      for (final lesson in course.lessons) {
        if (!lesson.isLearnerVisible) continue;
        records.add(
          _indexRecord(
            result: SearchResult(
              kind: SearchResultKind.lesson,
              id: lesson.id ??
                  normalizeSearchText(lesson.title).replaceAll(' ', '-'),
              parentId: course.id,
              title: lesson.title,
              snippet: lesson.description.isEmpty ? null : lesson.description,
              metadata: 'Somo katika “${course.title}”',
              isPremium: lesson.isPremium,
            ),
            body: lesson.description,
            tags: [lesson.moduleTitle, lesson.sourceTitle],
          ),
        );
      }
    }
    for (final problem in learningRepository.problemCategories) {
      records.add(
        _indexRecord(
          result: SearchResult(
            kind: SearchResultKind.problem,
            id: normalizeSearchText(problem.topic).replaceAll(' ', '-'),
            title: problem.title,
            snippet: problem.summary,
            metadata: 'Changamoto ya shamba',
          ),
          body: problem.summary,
          tags: [problem.topic, ...problem.examples],
        ),
      );
    }
    final courseIds = learningRepository.courses
        .map((course) => course.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final document in learningRepository.documents) {
      if (!_hasDocumentDestination(document, courseIds)) continue;
      records.add(
        _indexRecord(
          result: SearchResult(
            kind: SearchResultKind.document,
            id: document.id,
            parentId: document.courseId,
            title: document.title,
            snippet: document.description,
            metadata: [document.type, document.courseTitle]
                .where((value) => value.isNotEmpty)
                .join(' · '),
            isPremium: document.isPremium,
          ),
          body: document.description,
          tags: [document.courseTitle, document.type],
        ),
      );
    }
    for (final post in communityRepository.posts) {
      records.add(_indexCommunityPost(post));
    }

    _baseIndex = List.unmodifiable(records);
    _indexedGeneration = generation;
    _indexBuildCount += 1;
    return _baseIndex!;
  }

  bool _hasDocumentDestination(AppDocument document, Set<String> courseIds) {
    if (courseIds.contains(document.courseId)) return true;
    final uri = Uri.tryParse(document.url ?? '');
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Iterable<_IndexedRecord> _localCommunityOverlay(
    List<_IndexedRecord> baseIndex,
    List<CommunityPost>? localCommunityPosts,
  ) sync* {
    if (localCommunityPosts == null || localCommunityPosts.isEmpty) return;
    final cachedIds = {
      for (final record in baseIndex)
        if (record.kind == SearchResultKind.community) record.id,
    };
    for (final post in localCommunityPosts) {
      if (!cachedIds.contains(post.id)) yield _indexCommunityPost(post);
    }
  }
}

class _IndexedRecord {
  const _IndexedRecord({
    required this.result,
    required this.normalizedTitle,
    required this.normalizedSearchableBody,
    required this.normalizedTags,
    required this.titleTrigrams,
    required this.titleWordTrigrams,
  });

  final SearchResult result;
  final String normalizedTitle;
  final String normalizedSearchableBody;
  final Set<String> normalizedTags;
  final Set<String> titleTrigrams;
  final List<Set<String>> titleWordTrigrams;

  SearchResultKind get kind => result.kind;
  String get id => result.id;
}

class _Match {
  const _Match({required this.record, required this.score});

  final _IndexedRecord record;
  final int score;
}

_IndexedRecord _indexRecord({
  required SearchResult result,
  required String body,
  required List<String?> tags,
}) {
  final normalizedTitle = normalizeSearchText(result.title);
  final normalizedTags = tags
      .whereType<String>()
      .map(normalizeSearchText)
      .where((tag) => tag.isNotEmpty)
      .toSet();
  final normalizedBody = normalizeSearchText(body);
  return _IndexedRecord(
    result: result,
    normalizedTitle: normalizedTitle,
    normalizedSearchableBody:
        '$normalizedBody ${normalizedTags.join(' ')}'.trim(),
    normalizedTags: normalizedTags,
    titleTrigrams: _trigrams(normalizedTitle),
    titleWordTrigrams: [
      for (final word in normalizedTitle.split(' ')) _trigrams(word),
    ],
  );
}

_IndexedRecord _indexCommunityPost(CommunityPost post) {
  return _indexRecord(
    result: SearchResult(
      kind: SearchResultKind.community,
      id: post.id,
      title: _postTitle(post.content),
      snippet: post.content,
      metadata: [post.location, post.time]
          .where((value) => value.isNotEmpty)
          .join(' · '),
    ),
    body: post.content,
    tags: [...post.tags, post.relatedTopic],
  );
}

String normalizeSearchText(String value) {
  return unicode
      .nfkc(value)
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _includedInScope(SearchResultKind kind, SearchScope scope) {
  return switch (scope) {
    SearchScope.all => true,
    SearchScope.learning => kind == SearchResultKind.course ||
        kind == SearchResultKind.lesson ||
        kind == SearchResultKind.problem ||
        kind == SearchResultKind.document,
    SearchScope.community => kind == SearchResultKind.community,
    SearchScope.documents => kind == SearchResultKind.document,
  };
}

int _score(
  _IndexedRecord record,
  String query,
  Set<String> queryTrigrams,
) {
  final tokens = query.split(' ');
  var score = switch (record.kind) {
    SearchResultKind.course => 30,
    SearchResultKind.lesson => 25,
    SearchResultKind.problem => 20,
    SearchResultKind.document => 15,
    SearchResultKind.community => 0,
  };
  final baseline = score + (record.result.isPremium ? 0 : 10);
  score = baseline;
  if (record.normalizedTitle == query) score += 1000;
  if (record.normalizedTitle.startsWith(query)) score += 600;
  if (tokens.every(record.normalizedTitle.contains)) score += 300;

  var similarity = _trigramSimilarity(
    record.titleTrigrams,
    queryTrigrams,
  );
  for (final wordTrigrams in record.titleWordTrigrams) {
    final wordSimilarity = _trigramSimilarity(wordTrigrams, queryTrigrams);
    if (wordSimilarity > similarity) similarity = wordSimilarity;
  }
  if (similarity >= 0.3) score += (similarity * 200).round();
  if (record.normalizedTags.contains(query)) score += 160;
  if (tokens.every(record.normalizedSearchableBody.contains)) score += 100;
  return score > baseline ? score : 0;
}

void _insertTopMatch(List<_Match> matches, _Match candidate, int limit) {
  var insertionIndex = matches.length;
  for (var index = 0; index < matches.length; index += 1) {
    if (_compareMatches(candidate, matches[index]) < 0) {
      insertionIndex = index;
      break;
    }
  }
  if (insertionIndex >= limit) return;
  matches.insert(insertionIndex, candidate);
  if (matches.length > limit) matches.removeLast();
}

int _compareMatches(_Match left, _Match right) {
  final byScore = right.score.compareTo(left.score);
  if (byScore != 0) return byScore;
  final byKind = left.record.kind.name.compareTo(right.record.kind.name);
  if (byKind != 0) return byKind;
  return left.record.id.compareTo(right.record.id);
}

double _trigramSimilarity(Set<String> left, Set<String> right) {
  if (left.isEmpty || right.isEmpty) return 0;
  final shared = left.intersection(right).length;
  return (2 * shared) / (left.length + right.length);
}

Set<String> _trigrams(String value) {
  final chars = '  $value '.runes.toList();
  return {
    for (var index = 0; index <= chars.length - 3; index += 1)
      String.fromCharCodes(chars.sublist(index, index + 3)),
  };
}

String _postTitle(String content) {
  final value = content.trim();
  final codePoints = value.runes.toList(growable: false);
  return codePoints.length <= 72
      ? value
      : '${String.fromCharCodes(codePoints.take(69)).trimRight()}…';
}
