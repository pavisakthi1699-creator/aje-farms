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
