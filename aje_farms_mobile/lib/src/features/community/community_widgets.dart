part of '../../app.dart';

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(post.author.substring(0, 1),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${post.location} - ${post.time}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 14),
            Text(post.content),
            if (post.hasImage) ...[
              const SizedBox(height: 14),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 42),
                ),
              ),
            ],
            if (post.relatedTopic != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(post.relatedTopic!,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSnack(context, 'Jibu la mfano.'),
                    icon: const Icon(Icons.mode_comment_outlined),
                    label: const Text('Jibu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              AiChatScreen(initialPromptTopic: post.content)),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Uliza AI'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WhatsAppEscalationScreen()),
                  ),
                  icon: const Icon(Icons.phone_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityFilters extends StatelessWidget {
  const _CommunityFilters();

  @override
  Widget build(BuildContext context) {
    const filters = ['Zote', 'Mimea', 'Mifugo', 'Masoko'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ChoiceChip(
          selected: index == 0,
          label: Text(filters[index]),
          onSelected: (_) {},
        ),
      ),
    );
  }
}
