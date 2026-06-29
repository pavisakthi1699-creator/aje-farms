class CommunityPost {
  const CommunityPost({
    required this.author,
    required this.location,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
    required this.tags,
    required this.replies,
    this.relatedTopic,
    this.hasImage = false,
    this.isExpert = false,
    this.isUrgent = false,
  });

  final String author;
  final String location;
  final String time;
  final String content;
  final int likes;
  final int comments;
  final List<String> tags;
  final List<CommunityReply> replies;
  final String? relatedTopic;
  final bool hasImage;
  final bool isExpert;
  final bool isUrgent;
}

class CommunityReply {
  const CommunityReply({
    required this.author,
    required this.body,
    required this.time,
    this.isExpert = false,
  });

  final String author;
  final String body;
  final String time;
  final bool isExpert;
}
