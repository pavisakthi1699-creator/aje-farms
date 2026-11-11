import 'dart:io';
import 'dart:ui' show Locale;

import 'package:aje_farms_mobile/src/l10n/app_strings.dart';
import 'package:aje_farms_mobile/src/l10n/app_translations.dart';
import 'package:aje_farms_mobile/src/l10n/strings_en.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every `tr('…')` call with a literal key, including implicitly concatenated
/// literals (`tr('a ' 'b')`). Keys built at runtime (`tr(error.message)`) are
/// lookups of data and are allowed to fall back to Kiswahili.
final _trCall = RegExp(r"(?<![.\w])tr\(\s*((?:'(?:[^'\\\n]|\\.)*'\s*)+)[,)]");
final _literal = RegExp(r"'((?:[^'\\\n]|\\.)*)'");
final _placeholder = RegExp(r'\{(\w+)\}');

String _unescape(String source) => source.replaceAllMapped(
      RegExp(r'\\(.)'),
      (match) => match.group(1) == 'n' ? '\n' : match.group(1)!,
    );

Set<String> _placeholders(String text) =>
    _placeholder.allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(() => AppStrings.isEnglish = false);

  test('every literal passed to tr() has an English translation', () {
    final missing = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final call in _trCall.allMatches(source)) {
        final key = _literal
            .allMatches(call.group(1)!)
            .map((match) => _unescape(match.group(1)!))
            .join();
        if (AppTranslations.exactEnglish(key) == null) {
          missing.add('${file.path}: $key');
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason: 'Add these to app_translations.dart or strings_en.dart',
    );
  });

  test('strings_en.dart keeps the same placeholders in English', () {
    final mismatched = [
      for (final entry in englishStrings.entries)
        if (!setEquals(_placeholders(entry.key), _placeholders(entry.value)))
          entry.key,
    ];
    expect(mismatched, isEmpty);
  });

  test('tr returns Kiswahili by default and English when selected', () {
    expect(tr('Nyumbani'), 'Nyumbani');
    AppStrings.isEnglish = true;
    expect(tr('Nyumbani'), 'Home');
    expect(tr('Karibu, {name}', {'name': 'Asha'}), 'Welcome, Asha');
  });

  test('tr never rewrites text it has no exact entry for', () {
    AppStrings.isEnglish = true;
    expect(tr('Shamba la Mzee Juma'), 'Shamba la Mzee Juma');
  });

  test('context translation also uses strings_en.dart entries', () {
    expect(
      AppTranslations.translate('Ripoti ya AI imekaguliwa.', isEnglish: true),
      'AI report reviewed.',
    );
  });

  group('AppSessionController language', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('syncs tr() with the saved language preference', () async {
      final session = AppSessionController();
      await session.restore();
      expect(AppStrings.isEnglish, isFalse);

      await session.setLanguagePreference(const Locale('en'));
      expect(AppStrings.isEnglish, isTrue);

      AppStrings.isEnglish = false;
      final restored = AppSessionController();
      await restored.restore();
      expect(restored.state.languagePreference.languageCode, 'en');
      expect(AppStrings.isEnglish, isTrue);
    });

    test('keeps the language after sign-out', () async {
      final session = AppSessionController();
      await session.restore();
      await session.signInWithEmail('farmer@aje.test');
      await session.setLanguagePreference(const Locale('en'));

      await session.signOut();

      expect(session.state.languagePreference.languageCode, 'en');
      expect(session.hasStarted, isFalse);
    });
  });
}
