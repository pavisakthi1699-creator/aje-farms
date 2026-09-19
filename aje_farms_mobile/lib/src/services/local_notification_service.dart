import 'notification_service.dart';

class LocalNotificationService implements NotificationService {
  const LocalNotificationService();

  @override
  Future<NotificationInbox> inbox() async {
    return const NotificationInbox(
      settings: NotificationSettings(
        enabled: true,
        communityReplies: true,
        moderationUpdates: true,
        learningReminders: true,
      ),
      notifications: [],
    );
  }

  @override
  Future<void> markRead({required String notificationId}) async {}

  @override
  Future<NotificationSettings> updateSettings({required bool enabled}) async {
    return NotificationSettings(
      enabled: enabled,
      communityReplies: true,
      moderationUpdates: true,
      learningReminders: true,
    );
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {}
}
