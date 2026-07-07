import '../state/app_session.dart';

extension DashboardGreeting on AppSessionState {
  /// Swahili greeting for the home dashboard, personalized when possible.
  String get dashboardGreeting {
    final location = preferredLocation?.trim();
    if (location != null && location.isNotEmpty) {
      return 'Karibu, mkulima wa $location';
    }
    if (!isGuest && phoneNumber != null) {
      return 'Karibu tena';
    }
    return 'Karibu, Mkulima';
  }
}
