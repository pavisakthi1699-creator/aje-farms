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
    ChatMessage(
      role: ChatRole.model,
      text: tr(
        'Habari! Mimi ni Mwalimu AI. Nawezaje kukusaidia kuhusu kilimo leo?',
      ),
    ),
  ];
  bool _isLoading = false;

  Future<void> _reportAnswer(ChatMessage message) async {
    final messageId = message.messageId;
    if (messageId == null || message.isReported) return;
    final reason = await _selectAiReportReason(context);
    if (reason == null || !mounted) return;
    try {
      await context.dependencies.mwalimuAiService.reportAnswer(
        messageId,
        reason: reason,
      );
      if (!mounted) return;
      final index = _messages.indexOf(message);
      if (index >= 0) {
        setState(() {
          _messages[index] = ChatMessage(
            role: message.role,
            text: message.text,
            sources: message.sources,
            messageId: message.messageId,
            isReported: true,
          );
        });
      }
      showSuccessSnack(context, tr('Ripoti ya jibu la AI imepokelewa.'));
    } on MwalimuAiException catch (error) {
      if (mounted) showErrorSnack(context, tr(error.message));
    } catch (_) {
      if (mounted) showErrorSnack(context, tr('Imeshindikana kutuma ripoti.'));
    }
  }

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

  static String get _networkFailureReply => tr(
        'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au '
        'wasiliana na mtaalamu.',
      );
  static String get _pendingVerificationReply => tr(
        'Mwalimu AI itapatikana baada ya timu ya Chuo Kikuu Cha Mtaani kuthibitisha akaunti '
        'yako. Tunakujulisha mara akaunti yako itakapowashwa.',
      );

  Future<void> _send([String? value]) async {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, text: text));
      _controller.clear();
      _isLoading = true;
    });

    final aiService = context.dependencies.mwalimuAiService;
    MwalimuAiAnswer answer;

    try {
      answer = await aiService.answer(text);
    } on MwalimuAiException catch (error) {
      // A learner whose account an admin has not verified yet is not offline.
      // Telling them to check their connection sends them retrying forever, so
      // name the real reason and open the membership status screen.
      if (error.requiresVerifiedAccount) {
        answer = MwalimuAiAnswer(text: _pendingVerificationReply);
        if (mounted) AppNavigator.pushPaywall(context);
      } else {
        answer = MwalimuAiAnswer(text: _networkFailureReply);
      }
    } catch (_) {
      answer = MwalimuAiAnswer(text: _networkFailureReply);
    }

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        role: ChatRole.model,
        text: answer.text,
        sources: answer.sources,
        messageId: answer.messageId,
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
              label: tr('Hali: Mtandaoni'),
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
                    tr('Mtandaoni'),
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
          const SearchActionButton(),
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
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
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
                    onReport: () => _reportAnswer(_messages[index]),
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
              hintText: tr('Uliza ushauri kuhusu kilimo…'),
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
      return [
        tr('Nirekodi dalili gani?'),
        tr('Hatua salama ya kwanza'),
        tr('Nipige picha gani?'),
      ];
    }
    if (lower.contains('mbolea')) {
      return [
        tr('Nahitaji taarifa gani?'),
        tr('Je, nipime udongo?'),
        tr('Historia ya shamba'),
      ];
    }
    if (lower.contains('maji')) {
      return [
        tr('Ratiba ya kumwagilia'),
        tr('Maji yanasimama'),
        tr('Dalili za ukame'),
      ];
    }
    if (lower.contains('ufugaji')) {
      return [
        tr('Nirekodi dalili gani?'),
        tr('Usafi wa banda'),
        tr('Nimpateje daktari?'),
      ];
    }
    return [
      tr('Nirekodi dalili gani?'),
      tr('Hatua salama ya kwanza'),
      tr('Matatizo ya nyanya'),
    ];
  }
}

Future<String?> _selectAiReportReason(BuildContext context) {
  final reasons = <String, String>{
    'offensive': tr('Jibu linaudhi au halifai'),
    'unsafe': tr('Jibu linaweza kusababisha madhara'),
    'inaccurate': tr('Jibu si sahihi au linapotosha'),
    'personal_data': tr('Jibu lina taarifa binafsi'),
    'other': tr('Sababu nyingine'),
  };
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              tr('Kwa nini unaripoti jibu hili?'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final entry in reasons.entries)
            ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.of(context).pop(entry.key),
            ),
        ],
      ),
    ),
  );
}
