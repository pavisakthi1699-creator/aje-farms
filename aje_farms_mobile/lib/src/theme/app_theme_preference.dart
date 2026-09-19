enum AppThemePreference {
  system,
  light,
  dark;

  String get label => switch (this) {
        AppThemePreference.system => 'Mfumo',
        AppThemePreference.light => 'Mwanga',
        AppThemePreference.dark => 'Giza',
      };

  static AppThemePreference fromStorage(String? value) {
    return AppThemePreference.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}
