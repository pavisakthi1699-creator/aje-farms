import '../models/search_result.dart';

/// Optional arguments for [AiChatScreen] named-route navigation.
class AiChatRouteArgs {
  const AiChatRouteArgs({
    this.initialPromptTopic,
    this.initialPromptDetail,
    this.initialPrompt,
  });

  final String? initialPromptTopic;
  final String? initialPromptDetail;
  final String? initialPrompt;
}

class SearchRouteArgs {
  const SearchRouteArgs({
    this.scope = SearchScope.all,
    this.initialQuery,
  });

  final SearchScope scope;
  final String? initialQuery;
}

class CourseRouteArgs {
  const CourseRouteArgs({this.initialLessonId});

  final String? initialLessonId;
}

class ProblemRouteArgs {
  const ProblemRouteArgs({this.initialTopic});

  final String? initialTopic;
}
