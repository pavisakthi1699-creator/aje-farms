import '../models/search_result.dart';
import '../models/community_post.dart';
import '../repositories/community_repository.dart';
import '../repositories/learning_repository.dart';
import 'search_service.dart';

class LocalSearchService implements SearchService {
  const LocalSearchService({
    required this.learningRepository,
    required this.communityRepository,
  });

  final LearningRepository learningRepository;
  final CommunityRepository communityRepository;

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    final query = normalizeSearchText(request.query);
    if (query.runes.length < 2 || query.runes.length > 120) {
      throw const SearchException('Andika herufi 2 hadi 120 ili kutafuta.');
    }
    if (request.limit < 1 || request.limit > 50) {
      throw const SearchException('Idadi ya matokeo lazima iwe 1 hadi 50.');
    }
    final records = _recordsFor(
      request.scope,
      communityPosts: request.communityPosts,
    );
    final matches = records
        .map((record) {
          final relevance = _score(record, query);
          final savedBoost = relevance > 0 &&
                  request.scope == SearchScope.documents &&
                  record.kind == SearchResultKind.document &&
                  request.savedDocumentIds.contains(record.id)
              ? 2000
              : 0;
          return (record, relevance + savedBoost);
        })
        .where((match) => match.$2 > 0)
        .toList()
      ..sort((left, right) {
        final byScore = right.$2.compareTo(left.$2);
        if (byScore != 0) return byScore;
        final byKind = left.$1.kind.name.compareTo(right.$1.kind.name);
        return byKind != 0 ? byKind : left.$1.id.compareTo(right.$1.id);
      });

    return SearchResponse(
      query: query,
      scope: request.scope,
      results: [
        for (final match in matches.take(request.limit)) match.$1.result
      ],
      truncated: matches.length > request.limit,
      isOffline: true,
    );
  }

  List<_LocalRecord> _recordsFor(
    SearchScope scope, {
    List<CommunityPost>? communityPosts,
  }) {
    final records = <_LocalRecord>[];
    if (scope == SearchScope.all || scope == SearchScope.learning) {
      for (final course in learningRepository.courses) {
        records.add(
          _LocalRecord(
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
            _LocalRecord(
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
          _LocalRecord(
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
    }
    if (scope == SearchScope.all ||
        scope == SearchScope.learning ||
        scope == SearchScope.documents) {
      for (final document in learningRepository.documents) {
        records.add(
          _LocalRecord(
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
    }
    if (scope == SearchScope.all || scope == SearchScope.community) {
      for (final post in communityPosts ?? communityRepository.posts) {
        records.add(
          _LocalRecord(
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
          ),
        );
      }
    }
    return records;
  }
}

class _LocalRecord {
  const _LocalRecord({
    required this.result,
    required this.body,
    required this.tags,
  });

  final SearchResult result;
  final String body;
  final List<String?> tags;

  SearchResultKind get kind => result.kind;
  String get id => result.id;
}

String normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

int _score(_LocalRecord record, String query) {
  final title = normalizeSearchText(record.result.title);
  final body = normalizeSearchText(record.body);
  final tags = record.tags
      .whereType<String>()
      .map(normalizeSearchText)
      .where((tag) => tag.isNotEmpty)
      .toList();
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
  if (title == query) score += 1000;
  if (title.startsWith(query)) score += 600;
  if (tokens.every(title.contains)) score += 300;
  final similarity = <double>[
    _trigramSimilarity(title, query),
    ...title.split(' ').map((word) => _trigramSimilarity(word, query)),
  ].reduce((left, right) => left > right ? left : right);
  if (similarity >= 0.3) score += (similarity * 200).round();
  if (tags.contains(query)) score += 160;
  if (tokens.every('$body ${tags.join(' ')}'.contains)) score += 100;
  return score > baseline ? score : 0;
}

double _trigramSimilarity(String left, String right) {
  final leftSet = _trigrams(left);
  final rightSet = _trigrams(right);
  if (leftSet.isEmpty || rightSet.isEmpty) return 0;
  final shared = leftSet.intersection(rightSet).length;
  return (2 * shared) / (leftSet.length + rightSet.length);
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
  return value.length <= 72 ? value : '${value.substring(0, 69).trimRight()}…';
}
