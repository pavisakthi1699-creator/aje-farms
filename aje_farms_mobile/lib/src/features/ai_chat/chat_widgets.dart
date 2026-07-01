// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

enum ChatRole { user, model }

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final ChatRole role;
  final String text;
}

class IntakeContextCard extends StatelessWidget {
  const IntakeContextCard({required this.topic, this.detail});

  final String topic;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final hasDetail = detail != null && detail!.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.assignment_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Muktadha uliotumwa',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(hasDetail ? '$topic - $detail' : topic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.onEscalate});

  final ChatMessage message;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const ReplyActionChip(
                    icon: Icons.description_outlined,
                    label: 'Ona Kwenye Mafunzo',
                  ),
                  ReplyActionChip(
                    icon: Icons.support_agent,
                    label: 'Msaidizi wa Binadamu',
                    onTap: onEscalate,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReplyActionChip extends StatelessWidget {
  const ReplyActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Mwalimu AI anaandika...'),
        ],
      ),
    );
  }
}
