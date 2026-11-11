import '../l10n/app_strings.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  String get label => switch (this) {
        AppThemePreference.system => tr('Mfumo'),
        AppThemePreference.light => tr('Mwanga'),
        AppThemePreference.dark => tr('Giza'),
      };

  static AppThemePreference fromStorage(String? value) {
    return AppThemePreference.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}
