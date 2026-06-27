part of '../../app.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({this.initialPromptTopic, super.key});

  final String? initialPromptTopic;

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
    final topic = widget.initialPromptTopic;
    if (topic != null && topic.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send('Nina shida kuhusu $topic. Naweza kupata ushauri?');
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

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _messages
          .add(_ChatMessage(role: _ChatRole.model, text: _answerFor(text)));
      _isLoading = false;
    });
  }

  String _answerFor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('pasheni')) {
      return 'Kwa pasheni, hakikisha udongo unapisha maji vizuri na eneo halituamishi maji. Tumia nguzo na waya kusaidia mmea kupanda vizuri.\n\nChanzo: Mwongozo mfupi wa pasheni';
    }
    if (lower.contains('nyanya') || lower.contains('ukungu')) {
      return 'Kwa nyanya, anza na kitalu bora, epuka maji kusimama, na fuatilia dalili za ukungu mapema. Ondoa majani yaliyoathirika na tumia ushauri wa mtaalamu kabla ya dawa.\n\nChanzo: Mwongozo mfupi wa nyanya';
    }
    if (lower.contains('kuku') || lower.contains('ufugaji')) {
      return 'Kwa kuku, zingatia banda lenye hewa, usafi, maji safi, chakula bora na ratiba ya chanjo. Usafi wa banda hupunguza magonjwa.\n\nChanzo: Mwongozo wa kuku kwa wanaoanza';
    }
    return 'Hili ni jibu la mfano lililofungwa kwenye maarifa yaliyoidhinishwa. Eleza zao, eneo, dalili, na muda wa tatizo ili nipendekeze hatua inayofuata.\n\nChanzo: Taarifa zilizoidhinishwa';
  }

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Dawa gani kwa ukungu?',
      'Mbolea ya DAP',
      'Matatizo ya Nyanya'
    ];

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
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.length == 1)
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
                    onPressed: () => _send(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
