class AppDocument {
  const AppDocument({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseTitle,
    required this.description,
    required this.type,
    required this.sizeLabel,
    this.url,
    this.isPremium = false,
  });

  final String id;
  final String title;
  final String courseId;
  final String courseTitle;
  final String description;
  final String type;
  final String sizeLabel;
  final String? url;
  final bool isPremium;
}
