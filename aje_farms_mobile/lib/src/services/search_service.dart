import '../models/search_result.dart';

abstract interface class SearchService {
  Future<SearchResponse> search(SearchRequest request);
}

class SearchException implements Exception {
  const SearchException(this.message, {this.statusCode, this.retryAfter});

  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  bool get isAuthenticationFailure => statusCode == 401 || statusCode == 403;

  bool get isRecoverableFailure =>
      statusCode == null ||
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500);

  @override
  String toString() => message;
}
