import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/search_result.dart';
import 'backend_session_storage.dart';
import 'search_service.dart';

class BackendSearchService implements SearchService {
  BackendSearchService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    try {
      final token = await BackendSessionStorage.readToken();
      final headers = <String, String>{
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };
      final response = await _client
          .post(
            _baseUrl.resolve('/api/search'),
            headers: headers,
            body: jsonEncode({
              'query': request.query,
              'scope': request.scope.apiValue,
              'limit': request.limit,
              if (request.scope == SearchScope.documents)
                'savedDocumentIds': request.savedDocumentIds.toList()..sort(),
            }),
          )
          .timeout(timeout);
      Object? payload;
      try {
        payload = response.body.isEmpty
            ? const <String, dynamic>{}
            : jsonDecode(response.body);
      } on FormatException {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw SearchException(
            'Utafutaji haukukamilika. Jaribu tena.',
            statusCode: response.statusCode,
            retryAfter: response.statusCode == 429
                ? _retryAfter(response.headers['retry-after'])
                : null,
          );
        }
        throw const SearchException(
          'Huduma ya utafutaji imerudisha majibu yasiyo sahihi.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SearchException(
          payload is Map<String, dynamic> && payload['error'] is String
              ? payload['error'] as String
              : 'Utafutaji haukukamilika. Jaribu tena.',
          statusCode: response.statusCode,
          retryAfter: response.statusCode == 429
              ? _retryAfter(response.headers['retry-after'])
              : null,
        );
      }
      if (payload is! Map<String, dynamic>) {
        throw const SearchException(
          'Huduma ya utafutaji imerudisha majibu yasiyo sahihi.',
        );
      }
      final responsePayload = payload;
      final rawResults = responsePayload['results'];
      if (responsePayload['query'] is! String ||
          responsePayload['scope'] is! String ||
          !SearchScope.values.any(
            (scope) => scope.apiValue == responsePayload['scope'],
          ) ||
          responsePayload['truncated'] is! bool ||
          rawResults is! List ||
          rawResults.length > request.limit ||
          rawResults.any(
            (result) =>
                result is! Map<String, dynamic> || !_isValidResult(result),
          )) {
        throw const SearchException(
          'Huduma ya utafutaji imerudisha majibu yasiyo sahihi.',
        );
      }
      try {
        return SearchResponse(
          query: responsePayload['query'] as String,
          scope: SearchScope.fromApiValue(responsePayload['scope'] as String),
          results: (responsePayload['results'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(SearchResult.fromJson)
              .toList(),
          truncated: responsePayload['truncated'] as bool,
        );
      } on Object {
        throw const SearchException(
          'Huduma ya utafutaji imerudisha majibu yasiyo sahihi.',
        );
      }
    } on SearchException {
      rethrow;
    } on TimeoutException {
      throw const SearchException(
        'Mtandao umechukua muda mrefu. Matokeo yaliyohifadhiwa yatatumika.',
      );
    } on FormatException {
      throw const SearchException(
        'Huduma ya utafutaji imerudisha majibu yasiyo sahihi.',
      );
    } on http.ClientException {
      throw const SearchException(
        'Utafutaji wa mtandaoni haupatikani kwa sasa.',
      );
    }
  }
}

bool _isValidResult(Map<String, dynamic> result) {
  bool validString(Object? value, int maxLength, {bool optional = false}) {
    if (optional && value == null) return true;
    return value is String && value.isNotEmpty && value.length <= maxLength;
  }

  return validString(result['kind'], 20) &&
      validString(result['id'], 200) &&
      validString(result['parentId'], 200, optional: true) &&
      validString(result['title'], 500) &&
      validString(result['snippet'], 4000, optional: true) &&
      (result['metadata'] == null || validString(result['metadata'], 500)) &&
      (result['isPremium'] == null || result['isPremium'] is bool);
}

Duration? _retryAfter(String? value) {
  final seconds = int.tryParse(value ?? '');
  return seconds == null || seconds < 1 ? null : Duration(seconds: seconds);
}
