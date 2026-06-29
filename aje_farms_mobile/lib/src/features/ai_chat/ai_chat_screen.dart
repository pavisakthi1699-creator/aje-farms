part of '../../app.dart';

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
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.model,
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
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text));
      _controller.clear();
      _isLoading = true;
    });

    final response = await _mwalimuAiService.answer(text);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.model, text: response));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsFor(widget.initialPromptTopic);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mwalimu AI'),
            Text('Online',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: AppColors.blue,
              child: Icon(Icons.smart_toy_outlined, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.initialPromptTopic != null)
            _IntakeContextCard(
              topic: widget.initialPromptTopic!,
              detail: widget.initialPromptDetail,
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: _TypingBubble(),
                  );
                }
                return _ChatBubble(
                  message: _messages[index],
                  onEscalate: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WhatsAppEscalationScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1 && !_isLoading)
            SizedBox(
              height: 58,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ActionChip(
                  label: Text(suggestions[index]),
                  onPressed: () => _send(suggestions[index]),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Uliza ushauri kuhusu kilimo...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isLoading ? null : () => _send(),
                    icon: _isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
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
