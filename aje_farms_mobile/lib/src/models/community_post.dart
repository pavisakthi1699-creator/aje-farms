class CommunityPost {
  const CommunityPost({
    required this.author,
    required this.location,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
    this.relatedTopic,
    this.hasImage = false,
  });

  final String author;
  final String location;
  final String time;
  final String content;
  final int likes;
  final int comments;
  final String? relatedTopic;
  final bool hasImage;
}
