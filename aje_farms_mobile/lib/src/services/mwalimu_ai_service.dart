abstract interface class MwalimuAiService {
  Future<String> answer(String prompt);
}

class MwalimuAiException implements Exception {
  const MwalimuAiException(this.message);

  final String message;

  @override
  String toString() => 'MwalimuAiException: $message';
}
