// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    this.initialPromptTopic,
    this.initialPromptDetail,
    this.initialPrompt,
    super.key,
  });

  final String? initialPromptTopic;
  final String? initialPromptDetail;
  final String? initialPrompt;

  @override
  State<AiChatScreen> createState() => AiChatScreenState();
}

class AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      role: ChatRole.model,
      text:
          'Habari! Mimi ni Mwalimu AI. Nawezaje kukusaidia kuhusu kilimo leo?',
    ),
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt;
    if (prompt != null && prompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(prompt);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? value]) async {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, text: text));
      _controller.clear();
      _isLoading = true;
    });

    final aiService = context.dependencies.mwalimuAiService;
    var answer = const MwalimuAiAnswer(
      text:
          'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.',
    );

    try {
      answer = await aiService.answer(text);
    } catch (_) {
      answer = const MwalimuAiAnswer(
        text:
            'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.',
      );
    }

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        role: ChatRole.model,
        text: answer.text,
        sources: answer.sources,
      ));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsFor(widget.initialPromptTopic);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mwalimu AI'),
            Semantics(
              label: 'Hali: Mtandaoni',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.circle,
                      size: 10,
                      color: context.colors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Mtandaoni',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ExcludeSemantics(
              child: Container(
                width: AppA11y.minTouchTarget,
                height: AppA11y.minTouchTarget,
                decoration: AppDecorations.circleIconButton(context),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.initialPromptTopic != null)
            AppLayout(
              child: IntakeContextCard(
                topic: widget.initialPromptTopic!,
                detail: widget.initialPromptDetail,
              ),
            ),
          Expanded(
            child: AppLayout(
              child: ListView.separated(
              key: AppPageStorage.aiChat,
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: TypingBubble(),
                  );
                }
                return ChatBubble(
                  message: _messages[index],
                  onEscalate: () => AppNavigator.pushWhatsApp(context),
                );
              },
            ),
            ),
          ),
          if (_messages.length == 1 && !_isLoading)
            AppLayout(
              child: SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) => ActionChip(
                  label: Text(
                    suggestions[index],
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  onPressed: () {
                    AppFeedback.selection();
                    _send(suggestions[index]);
                  },
                ),
              ),
            ),
            ),
          AppLayout(
            child: ChatComposerBar(
              controller: _controller,
              isLoading: _isLoading,
              hintText: 'Uliza ushauri kuhusu kilimo...',
              onSend: _send,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _suggestionsFor(String? topic) {
    final lower = topic?.toLowerCase() ?? '';
    if (lower.contains('wadudu')) {
      return ['Dalili zipi ni hatari?', 'Nifanye nini leo?', 'Dawa ya kuanza'];
    }
    if (lower.contains('mbolea')) {
      return ['Nitumie mbolea gani?', 'Kipimo kwa shimo', 'Udongo umechoka'];
    }
    if (lower.contains('maji')) {
      return ['Ratiba ya kumwagilia', 'Maji yanasimama', 'Dalili za ukame'];
    }
    if (lower.contains('ufugaji')) {
      return ['Ratiba ya chanjo', 'Chakula cha kuku', 'Banda lenye hewa'];
    }
    return ['Dawa gani kwa ukungu?', 'Mbolea ya DAP', 'Matatizo ya Nyanya'];
  }
}
