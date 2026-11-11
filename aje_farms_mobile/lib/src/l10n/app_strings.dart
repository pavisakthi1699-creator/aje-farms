import 'app_translations.dart';

/// Mirrors the interface language chosen in `AppSessionState.languagePreference`
/// so [tr] can be called anywhere — widgets, enum labels, validators — without
/// a `BuildContext`. `AppSessionController` keeps it in sync.
class AppStrings {
  AppStrings._();

  static bool isEnglish = false;

  /// Value sent to the API (for example so Mwalimu AI answers in English).
  static String get languageCode => isEnglish ? 'en' : 'sw';
}

/// Translates a Kiswahili interface string into the current language.
///
/// Uses the same dictionary as `'…'.tr(context)` (see [AppTranslations]), but
/// only exact matches: interface text is never partially rewritten. Strings
/// without an English entry fall back to Kiswahili. Values are substituted
/// into `{name}` placeholders after lookup:
///
/// ```dart
/// tr('Karibu, {name}', {'name': name});
/// ```
String tr(String swahili, [Map<String, Object?>? args]) {
  var text = AppStrings.isEnglish
      ? (AppTranslations.exactEnglish(swahili) ?? swahili)
      : swahili;
  if (args != null) {
    args.forEach((key, value) {
      text = text.replaceAll('{$key}', '${value ?? ''}');
    });
  }
  return text;
}
