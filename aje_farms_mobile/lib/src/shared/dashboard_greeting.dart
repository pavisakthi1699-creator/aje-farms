import '../state/app_session.dart';
import '../l10n/app_strings.dart';

extension DashboardGreeting on AppSessionState {
  /// Swahili greeting for the home dashboard, personalized when possible.
  String get dashboardGreeting {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return tr('Karibu, {name}', {'name': name});
    }
    final location = preferredLocation?.trim();
    if (location != null && location.isNotEmpty) {
      return tr('Karibu, mkulima wa {location}', {'location': location});
    }
    if (!isGuest && email != null) {
      return tr('Karibu tena');
    }
    return tr('Karibu, Mkulima');
  }
}
