// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    required this.post,
    required this.onOpen,
    this.compact = false,
  });

  final CommunityPost post;
  final VoidCallback onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        'Post ya ${post.author} kutoka ${post.location}. ${post.content}';
    return AccessibleTappable(
      label: semanticLabel,
      hint: post.isUrgent ? 'Inahitaji haraka' : null,
      onTap: onOpen,
      child: Card(
        key: ValueKey(
          'community-post-${post.id.isEmpty ? post.author : post.id}',
        ),
        child: InteractiveInk(
          borderRadius: AppRadius.xl,
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colors.primaryContainer,
                      child: Text(_authorInitial(post.author),
                          style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (post.isExpert)
                            Text(
                              'Mtaalamu aliyethibitishwa',
                              style: accessibleCaption(
                                context,
                                color: context.colors.primary,
                              ),
                            ),
                          Text(
                            '${post.location} - ${post.time}',
                            style: accessibleCaption(context),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Chaguo zaidi',
                      child: Icon(Icons.more_vert, color: context.colors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  post.content,
                  maxLines: compact ? 3 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (post.isUrgent)
                      CommunityBadge(
                        icon: Icons.priority_high,
                        label: 'Inahitaji haraka',
                        color: context.colors.secondary,
                      ),
                    for (final tag in compact ? post.tags.take(2) : post.tags)
                      CommunityBadge(
                        icon: Icons.local_offer_outlined,
                        label: tag,
                        color: context.colors.primary,
                      ),
                  ],
                ),
                if (!compact && post.hasImage) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: context.colors.mint,
                        border: AppElevation.borderSubtle(context),
                      ),
                      child: post.imageUrl != null
                          ? AppPhoto(source: post.imageUrl!)
                          : Center(
                              child: Icon(Icons.image_outlined,
                                  color: context.colors.primary, size: 42),
                            ),
                    ),
                  ),
                ],
                if (!compact && post.relatedTopic != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: AppDecorations.pastelPanel(
                      context,
                      context.colors.primaryContainer,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: context.colors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            post.relatedTopic!,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      '${post.likes} wamependa',
                      style: accessibleCaption(context),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${post.comments} majibu',
                      style: accessibleCaption(context),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppFeedback.tap();
                            onOpen();
                          },
                          icon: const Icon(Icons.mode_comment_outlined),
                          label: const Text('Jibu'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            AppFeedback.tap();
                            AppNavigator.pushAiChat(
                              context,
                              initialPromptTopic: 'Jamii',
                              initialPrompt:
                                  'Nimesoma post ya jamii: "${post.content}". Nisaidie kutoa ushauri salama na wa vitendo.',
                            );
                          },
                          icon: const Icon(Icons.smart_toy_outlined),
                          label: const Text('Uliza AI'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.outlined(
                        tooltip: 'Piga simu kwa msaada',
                        onPressed: () {
                          AppFeedback.tap();
                          AppNavigator.pushWhatsApp(context);
                        },
                        icon: const Icon(Icons.phone_outlined),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommunityFilters extends StatelessWidget {
  const CommunityFilters({
    required this.topics,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> topics;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = ['Zote', ...topics];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) => ChoiceChip(
          key: ValueKey('community-filter-${filters[index]}'),
          selected: selectedFilter == filters[index],
          label: Text(filters[index]),
          onSelected: (_) {
            AppFeedback.selection();
            onSelected(filters[index]);
          },
        ),
      ),
    );
  }
}

class CommunitySummaryCard extends StatelessWidget {
  const CommunitySummaryCard({required this.posts});

  final List<CommunityPost> posts;

  @override
  Widget build(BuildContext context) {
    final expertReplies = posts
        .expand((post) => post.replies)
        .where((reply) => reply.isExpert)
        .length;
    return Card(
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  AppDecorations.pastelPanel(context, context.colors.surface),
              child: Icon(Icons.groups_outlined, color: context.colors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jamii ya Chuo Kikuu Cha Mtaani',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${posts.length} mijadala, $expertReplies majibu ya wataalamu.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.muted,
                        ),
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

class CommunityBadge extends StatelessWidget {
  const CommunityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: accessibleCaption(context, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscussionActionPanel extends StatelessWidget {
  const DiscussionActionPanel({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surfaceMuted,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hatua inayofuata',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tumia AI kupanga muhtasari wa mjadala au mpe mtaalamu muktadha wake.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      AppFeedback.tap();
                      AppNavigator.pushAiChat(
                        context,
                        initialPromptTopic: 'Jamii',
                        initialPrompt:
                            'Fupisha mjadala huu, taja taarifa ambazo hazijathibitishwa, na orodhesha maswali ya kumuuliza mtaalamu: "${post.content}".',
                      );
                    },
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Andaa muhtasari'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.outlined(
                  tooltip: 'Mtaalamu',
                  onPressed: () {
                    AppFeedback.tap();
                    AppNavigator.pushWhatsApp(context);
                  },
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

class CommunityReplyTile extends StatelessWidget {
  const CommunityReplyTile({required this.reply});

  final CommunityReply reply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        color: context.colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: reply.isExpert
                    ? context.colors.primary
                    : context.colors.primaryContainer,
                child: Icon(
                  reply.isExpert ? Icons.verified : Icons.person_outline,
                  color: reply.isExpert
                      ? context.colors.onPrimary
                      : context.colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reply.author,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          reply.time,
                          style: accessibleCaption(context),
                        ),
                      ],
                    ),
                    if (reply.isExpert)
                      Text(
                        'Mtaalamu',
                        style: accessibleCaption(
                          context,
                          color: context.colors.primary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      reply.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Authors are server-derived display names, but guard against an empty label
// so the avatar never throws on substring.
String _authorInitial(String author) {
  final trimmed = author.trim();
  if (trimmed.isEmpty) return 'M';
  return trimmed.characters.first.toUpperCase();
}
