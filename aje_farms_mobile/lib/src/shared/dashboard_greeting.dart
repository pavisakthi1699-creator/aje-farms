import '../state/app_session.dart';

extension DashboardGreeting on AppSessionState {
  /// Swahili greeting for the home dashboard, personalized when possible.
  String get dashboardGreeting {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return 'Karibu, $name';
    }
    final location = preferredLocation?.trim();
    if (location != null && location.isNotEmpty) {
      return 'Karibu, mkulima wa $location';
    }
    if (!isGuest && email != null) {
      return 'Karibu tena';
    }
    return 'Karibu, Mkulima';
  }
}
