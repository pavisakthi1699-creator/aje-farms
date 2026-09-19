import '../state/app_session.dart';

extension DashboardGreeting on AppSessionState {
  /// Swahili or English greeting for the home dashboard, personalized when possible.
  String get dashboardGreeting {
    final isEn = languagePreference.languageCode == 'en';
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return isEn ? 'Welcome, $name' : 'Karibu, $name';
    }
    final location = preferredLocation?.trim();
    if (location != null && location.isNotEmpty) {
      return isEn ? 'Welcome, farmer from $location' : 'Karibu, mkulima wa $location';
    }
    if (!isGuest && email != null) {
      return isEn ? 'Welcome back' : 'Karibu tena';
    }
    return isEn ? 'Welcome, Farmer' : 'Karibu, Mkulima';
  }
}
