class CommunityPost {
  const CommunityPost({
    this.id = '',
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

  final String id;
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

  CommunityPost copyWith({
    String? id,
    String? author,
    String? location,
    String? time,
    String? content,
    int? likes,
    int? comments,
    List<String>? tags,
    List<CommunityReply>? replies,
    String? relatedTopic,
    bool? hasImage,
    bool? isExpert,
    bool? isUrgent,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      author: author ?? this.author,
      location: location ?? this.location,
      time: time ?? this.time,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      tags: tags ?? this.tags,
      replies: replies ?? this.replies,
      relatedTopic: relatedTopic ?? this.relatedTopic,
      hasImage: hasImage ?? this.hasImage,
      isExpert: isExpert ?? this.isExpert,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
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
