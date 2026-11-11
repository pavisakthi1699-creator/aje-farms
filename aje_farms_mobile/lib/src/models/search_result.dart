import '../l10n/app_strings.dart';
import 'community_post.dart';

enum SearchScope {
  all('all', 'Zote'),
  learning('learning', 'Mafunzo'),
  community('community', 'Jamii'),
  documents('documents', 'Nyaraka');

  const SearchScope(this.apiValue, this.labelSw);

  final String apiValue;

  /// Kiswahili source label; [label] is the display text.
  final String labelSw;
  String get label => tr(labelSw);

  static SearchScope fromApiValue(String value) {
    return values.firstWhere(
      (scope) => scope.apiValue == value,
      orElse: () => SearchScope.all,
    );
  }
}

enum SearchResultKind { course, lesson, document, problem, community }

class SearchRequest {
  const SearchRequest({
    required this.query,
    this.scope = SearchScope.all,
    this.limit = 20,
    this.savedDocumentIds = const {},
    this.localCommunityPosts,
  });

  final String query;
  final SearchScope scope;
  final int limit;
  final Set<String> savedDocumentIds;
  final List<CommunityPost>? localCommunityPosts;
}

class SearchResult {
  const SearchResult({
    required this.kind,
    required this.id,
    required this.title,
    required this.metadata,
    this.parentId,
    this.snippet,
    this.isPremium = false,
  });

  final SearchResultKind kind;
  final String id;
  final String? parentId;
  final String title;
  final String? snippet;
  final String metadata;
  final bool isPremium;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      kind: SearchResultKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () =>
            throw const FormatException('Unknown search result kind.'),
      ),
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      title: json['title'] as String,
      snippet: json['snippet'] as String?,
      metadata: json['metadata'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}

class SearchResponse {
  const SearchResponse({
    required this.query,
    required this.scope,
    required this.results,
    required this.truncated,
    this.isOffline = false,
  });

  final String query;
  final SearchScope scope;
  final List<SearchResult> results;
  final bool truncated;
  final bool isOffline;
}
