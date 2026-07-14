class NotificationInbox {
  const NotificationInbox({
    required this.settings,
    required this.notifications,
  });

  final NotificationSettings settings;
  final List<AppNotification> notifications;
}

class NotificationSettings {
  const NotificationSettings({
    required this.enabled,
    required this.communityReplies,
    required this.moderationUpdates,
    required this.learningReminders,
  });

  final bool enabled;
  final bool communityReplies;
  final bool moderationUpdates;
  final bool learningReminders;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}

abstract interface class NotificationService {
  Future<NotificationInbox> inbox(String phoneNumber);
  Future<NotificationSettings> updateSettings({
    required String phoneNumber,
    required bool enabled,
  });
  Future<void> registerDevice({
    required String phoneNumber,
    required String token,
    required String platform,
  });
  Future<void> markRead({
    required String phoneNumber,
    required String notificationId,
  });
}

class NotificationException implements Exception {
  const NotificationException(this.message);

  final String message;

  @override
  String toString() => 'NotificationException: $message';
}
