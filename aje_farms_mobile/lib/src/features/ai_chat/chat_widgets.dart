part of '../../app.dart';

enum _ChatRole { user, model }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _ChatRole role;
  final String text;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.text : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text,
                style: TextStyle(
                    color: isUser ? Colors.white : AppColors.text,
                    height: 1.35)),
            if (!isUser && message.text.contains('Chanzo:')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Ona Kwenye Mafunzo',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: const Text('Mwalimu AI anaandika...'),
    );
  }
}
