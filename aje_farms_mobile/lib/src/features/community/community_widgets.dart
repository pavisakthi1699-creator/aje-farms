part of '../../app.dart';

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post, required this.onOpen});

  final CommunityPost post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        if (post.isExpert)
                          const Text('Mtaalamu aliyethibitishwa',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (post.isUrgent)
                    const _CommunityBadge(
                      icon: Icons.priority_high,
                      label: 'Inahitaji haraka',
                      color: AppColors.secondary,
                    ),
                  for (final tag in post.tags)
                    _CommunityBadge(
                      icon: Icons.local_offer_outlined,
                      label: tag,
                      color: AppColors.primary,
                    ),
                ],
              ),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('${post.likes} likes',
                      style: const TextStyle(
                          color: AppColors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Text('${post.comments} majibu',
                      style: const TextStyle(
                          color: AppColors.muted, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.mode_comment_outlined),
                      label: const Text('Jibu'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AiChatScreen(
                            initialPromptTopic: 'Jamii',
                            initialPrompt:
                                'Nimesoma post ya jamii: "${post.content}". Nisaidie kutoa ushauri salama na wa vitendo.',
                          ),
                        ),
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
      ),
    );
  }
}

class _CommunityFilters extends StatelessWidget {
  const _CommunityFilters({
    required this.selectedFilter,
    required this.onSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = ['Zote', 'Magonjwa', 'Mifugo', 'Masoko', 'Kuku', 'Nyanya'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ChoiceChip(
          key: ValueKey('community-filter-${filters[index]}'),
          selected: selectedFilter == filters[index],
          label: Text(filters[index]),
          onSelected: (_) => onSelected(filters[index]),
        ),
      ),
    );
  }
}

class _CommunitySummaryCard extends StatelessWidget {
  const _CommunitySummaryCard({required this.posts});

  final List<CommunityPost> posts;

  @override
  Widget build(BuildContext context) {
    final expertReplies = posts
        .expand((post) => post.replies)
        .where((reply) => reply.isExpert)
        .length;
    return Card(
      color: AppColors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.groups_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jamii hai leo',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${posts.length} mijadala, $expertReplies majibu ya wataalamu.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionActionPanel extends StatelessWidget {
  const _DiscussionActionPanel({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hatua inayofuata',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
                'Tumia AI kupata muhtasari au mpe mtaalamu muktadha wa mjadala huu.'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AiChatScreen(
                          initialPromptTopic: 'Jamii',
                          initialPrompt:
                              'Fupisha mjadala huu na pendekeza jibu: "${post.content}".',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Fupisha na AI'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Mtaalamu',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WhatsAppEscalationScreen()),
                  ),
                  icon: const Icon(Icons.support_agent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityReplyTile extends StatelessWidget {
  const _CommunityReplyTile({required this.reply});

  final CommunityReply reply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: reply.isExpert
                  ? AppColors.primary
                  : AppColors.primaryContainer,
              child: Icon(
                reply.isExpert ? Icons.verified : Icons.person_outline,
                color: reply.isExpert ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(reply.author,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Text(reply.time,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  if (reply.isExpert)
                    const Text('Mtaalamu',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(reply.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
